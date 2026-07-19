package com.skillforge.storage.controller;

import com.skillforge.common.api.ApiResponse;
import com.skillforge.common.exception.ResourceNotFoundException;
import com.skillforge.storage.service.StorageService;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.core.io.Resource;
import org.springframework.core.io.UrlResource;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.net.MalformedURLException;
import java.nio.file.Files;
import java.nio.file.Path;

@RestController
public class StorageController {
    private final StorageService storageService;

    public StorageController(StorageService storageService) {
        this.storageService = storageService;
    }

    @PostMapping("/api/v1/storage/upload")
    public ResponseEntity<ApiResponse<String>> uploadFile(@RequestParam("file") MultipartFile file,
                                                          HttpServletRequest servletRequest) {
        String fileUrl = storageService.store(file);
        return ResponseEntity.ok(ApiResponse.success("File uploaded successfully", fileUrl, servletRequest.getRequestURI()));
    }

    @GetMapping("/api/v1/storage/files/{filename:.+}")
    public ResponseEntity<Resource> serveFile(@PathVariable String filename) {
        try {
            Path file = storageService.load(filename);
            Resource resource = new UrlResource(file.toUri());
            if (resource.exists() || resource.isReadable()) {
                String contentType = Files.probeContentType(file);
                if (contentType == null) {
                    // Fallbacks
                    if (filename.endsWith(".pdf")) {
                        contentType = "application/pdf";
                    } else if (filename.endsWith(".mp4")) {
                        contentType = "video/mp4";
                    } else {
                        contentType = "application/octet-stream";
                    }
                }
                return ResponseEntity.ok()
                        .contentType(MediaType.parseMediaType(contentType))
                        .header(HttpHeaders.CONTENT_DISPOSITION, "inline; filename=\"" + resource.getFilename() + "\"")
                        .body(resource);
            } else {
                throw new ResourceNotFoundException("Could not read file: " + filename);
            }
        } catch (MalformedURLException e) {
            throw new ResourceNotFoundException("Could not read file: " + filename);
        } catch (IOException e) {
            throw new ResourceNotFoundException("Could not determine content type of file: " + filename);
        }
    }
}
