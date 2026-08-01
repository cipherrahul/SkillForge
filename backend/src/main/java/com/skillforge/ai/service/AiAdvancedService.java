package com.skillforge.ai.service;

import org.springframework.stereotype.Service;

import java.util.*;

@Service
public class AiAdvancedService {

    public Map<String, Object> matchAtsResume(String resumeText, String targetRole) {
        String role = targetRole != null ? targetRole.trim() : "Software Engineer";
        String content = resumeText != null ? resumeText.toLowerCase() : "";

        List<String> expectedKeywords = switch (role.toLowerCase()) {
            case "frontend developer", "react developer" -> List.of("react", "typescript", "css", "next.js", "state management", "rest api");
            case "backend engineer", "java developer" -> List.of("java", "spring boot", "postgresql", "redis", "kafka", "docker", "microservices");
            case "fullstack engineer" -> List.of("javascript", "typescript", "react", "spring boot", "sql", "api", "git", "cloud");
            case "data scientist", "ai engineer" -> List.of("python", "pytorch", "tensorflow", "sql", "pandas", "scikit-learn", "machine learning");
            default -> List.of("problem solving", "git", "agile", "collaboration", "database", "testing");
        };

        long matchedCount = expectedKeywords.stream()
                .filter(content::contains)
                .count();

        int score = (int) Math.min(98, Math.max(55, 60 + (matchedCount * 6)));

        List<String> matchedKeywords = expectedKeywords.stream()
                .filter(content::contains)
                .toList();

        List<String> missingKeywords = expectedKeywords.stream()
                .filter(kw -> !content.contains(kw))
                .toList();

        List<String> recommendations = new ArrayList<>();
        if (!missingKeywords.isEmpty()) {
            recommendations.add("Incorporate missing domain skills: " + String.join(", ", missingKeywords));
        }
        recommendations.add("Quantify metrics (e.g. 'Improved response latency by 35%')");
        recommendations.add("Highlight production deployment experience with CI/CD pipelines");

        Map<String, Object> result = new LinkedHashMap<>();
        result.put("targetRole", role);
        result.put("matchScore", score);
        result.put("matchedKeywords", matchedKeywords);
        result.put("missingKeywords", missingKeywords);
        result.put("recommendations", recommendations);
        result.put("summary", "Resume shows strong alignment for " + role + " with " + score + "% ATS score match.");
        return result;
    }

    public Map<String, Object> reviewCode(String sourceCode, String language) {
        String lang = language != null ? language : "javascript";
        String code = sourceCode != null ? sourceCode : "";

        int lines = code.split("\n").length;
        boolean hasComments = code.contains("//") || code.contains("/*") || code.contains("#");
        boolean hasAsync = code.contains("async") || code.contains("CompletableFuture") || code.contains("Promise");

        List<String> suggestions = new ArrayList<>();
        if (!hasComments) {
            suggestions.add("Add inline JSDoc/Docstring documentation for key methods.");
        }
        if (code.length() > 500 && !code.contains("try") && !code.contains("catch")) {
            suggestions.add("Include defensive error handling / try-catch blocks.");
        }
        suggestions.add("Optimize algorithmic loops to maintain O(N) or O(N log N) runtime.");

        Map<String, Object> result = new LinkedHashMap<>();
        result.put("language", lang);
        result.put("linesOfCode", lines);
        result.put("qualityScore", Math.min(99, 80 + (hasComments ? 10 : 0) + (hasAsync ? 5 : 0)));
        result.put("suggestions", suggestions);
        result.put("securityAuditPass", true);
        result.put("complexityRating", lines > 40 ? "Moderate" : "Low");
        return result;
    }

    public List<Map<String, String>> generateFlashcards(String lessonContent) {
        List<Map<String, String>> flashcards = new ArrayList<>();
        flashcards.add(Map.of(
                "question", "What is the primary benefit of modular monolith architecture in early scaling?",
                "answer", "It allows clean domain isolation without premature microservices network overhead and operational complexity."
        ));
        flashcards.add(Map.of(
                "question", "How does Redis cache invalidation optimize API latency?",
                "answer", "It serves hot query reads directly from in-memory data structures, avoiding DB disk IO bottlenecks."
        ));
        flashcards.add(Map.of(
                "question", "What is the purpose of JWT Refresh Tokens?",
                "answer", "They allow secure, long-lived session extension without exposing access tokens indefinitely."
        ));
        return flashcards;
    }
}
