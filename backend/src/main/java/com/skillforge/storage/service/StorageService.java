package com.skillforge.storage.service;

import com.skillforge.common.exception.BadRequestException;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;
import java.util.Objects;
import java.util.UUID;

@Service
public class StorageService {
    private final Path rootLocation = Paths.get("uploads");

    public StorageService() {
        try {
            Files.createDirectories(rootLocation);
        } catch (IOException e) {
            throw new RuntimeException("Could not initialize storage directory", e);
        }
    }

    public String store(MultipartFile file) {
        if (file == null || file.isEmpty()) {
            throw new BadRequestException("Failed to store empty file");
        }

        String originalFilename = file.getOriginalFilename();
        if (originalFilename == null) {
            originalFilename = "file";
        }

        // Clean originalFilename to prevent directory traversal
        String cleanedName = Paths.get(originalFilename).getFileName().toString();
        
        // Generate unique name: uuid_originalName
        String uniqueName = UUID.randomUUID().toString() + "_" + cleanedName;

        try {
            Path destinationFile = this.rootLocation.resolve(Paths.get(uniqueName))
                    .normalize().toAbsolutePath();

            if (!destinationFile.getParent().equals(this.rootLocation.toAbsolutePath())) {
                // Security check
                throw new BadRequestException("Cannot store file outside current directory");
            }

            try (var inputStream = file.getInputStream()) {
                Files.copy(inputStream, destinationFile, StandardCopyOption.REPLACE_EXISTING);
            }
        } catch (IOException e) {
            throw new BadRequestException("Failed to store file: " + e.getMessage());
        }

        return "/api/v1/storage/files/" + uniqueName;
    }

    public String storeBytes(byte[] content, String filename) {
        if (content == null || filename == null) {
            throw new BadRequestException("Content and filename are required");
        }

        String cleanedName = Paths.get(filename).getFileName().toString();
        String uniqueName = UUID.randomUUID().toString() + "_" + cleanedName;

        try {
            Path destinationFile = this.rootLocation.resolve(Paths.get(uniqueName))
                    .normalize().toAbsolutePath();

            if (!destinationFile.getParent().equals(this.rootLocation.toAbsolutePath())) {
                throw new BadRequestException("Cannot store file outside current directory");
            }

            Files.write(destinationFile, content);
        } catch (IOException e) {
            throw new BadRequestException("Failed to store file: " + e.getMessage());
        }

        return "/api/v1/storage/files/" + uniqueName;
    }

    public Path load(String filename) {
        Path file = rootLocation.resolve(filename).normalize();
        if (!file.getParent().equals(rootLocation.toAbsolutePath().normalize())) {
            throw new BadRequestException("Access denied");
        }
        return file;
    }
}
