package com.focusedai.codecompiler;

import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.scheduling.annotation.Scheduled;

import java.security.MessageDigest;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.TimeUnit;
import java.nio.charset.StandardCharsets;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Service
public class CompilationCacheService {
    
    private final Map<String, CachedResult> cache = new ConcurrentHashMap<>();
    private static final long CACHE_TTL_MINUTES = 30; // Cache for 30 minutes
    private static final int MAX_CACHE_SIZE = 1000; // Maximum cached results
    
    public CompilationResult getCachedResult(String language, List<MultipartFile> files) {
        String cacheKey = generateCacheKey(language, files);
        CachedResult cached = cache.get(cacheKey);
        
        if (cached != null && !cached.isExpired()) {
            System.out.println("✅ Cache HIT for key: " + cacheKey.substring(0, 8) + "...");
            return cached.result;
        }
        
        if (cached != null && cached.isExpired()) {
            cache.remove(cacheKey);
            System.out.println("⏰ Cache EXPIRED for key: " + cacheKey.substring(0, 8) + "...");
        }
        
        System.out.println("❌ Cache MISS for key: " + cacheKey.substring(0, 8) + "...");
        return null;
    }
    
    public void cacheResult(String language, List<MultipartFile> files, CompilationResult result) {
        // Only cache successful compilations to avoid caching errors
        if (result.isSuccess()) {
            String cacheKey = generateCacheKey(language, files);
            
            // Prevent cache from growing too large
            if (cache.size() >= MAX_CACHE_SIZE) {
                cleanupOldestEntries();
            }
            
            cache.put(cacheKey, new CachedResult(result));
            System.out.println("💾 Cached result for key: " + cacheKey.substring(0, 8) + "... (cache size: " + cache.size() + ")");
        } else {
            System.out.println("⚠️ Not caching failed compilation");
        }
    }
    
    private String generateCacheKey(String language, List<MultipartFile> files) {
        try {
            MessageDigest md = MessageDigest.getInstance("SHA-256");
            
            // Add language to hash
            md.update(language.getBytes(StandardCharsets.UTF_8));
            
            // Sort files by name for consistent hashing regardless of upload order
            files.stream()
                .sorted((a, b) -> {
                    String nameA = a.getOriginalFilename() != null ? a.getOriginalFilename() : "";
                    String nameB = b.getOriginalFilename() != null ? b.getOriginalFilename() : "";
                    return nameA.compareTo(nameB);
                })
                .forEach(file -> {
                    try {
                        // Add filename to hash
                        String filename = file.getOriginalFilename() != null ? file.getOriginalFilename() : "unknown";
                        md.update(filename.getBytes(StandardCharsets.UTF_8));
                        
                        // Add file content to hash
                        md.update(file.getBytes());
                    } catch (Exception e) {
                        throw new RuntimeException("Error processing file for cache key", e);
                    }
                });
            
            // Convert hash to hex string
            byte[] hash = md.digest();
            StringBuilder hexString = new StringBuilder();
            for (byte b : hash) {
                hexString.append(String.format("%02x", b));
            }
            return hexString.toString();
            
        } catch (Exception e) {
            throw new RuntimeException("Failed to generate cache key", e);
        }
    }
    
    private void cleanupOldestEntries() {
        if (cache.size() < MAX_CACHE_SIZE) return;
        
        // Remove the oldest 20% of entries
        int entriesToRemove = (int) (cache.size() * 0.2);
        
        cache.entrySet().stream()
            .sorted((a, b) -> Long.compare(a.getValue().timestamp, b.getValue().timestamp))
            .limit(entriesToRemove)
            .map(Map.Entry::getKey)
            .collect(Collectors.toList())
            .forEach(cache::remove);
            
        System.out.println("🧹 Cleaned up " + entriesToRemove + " old cache entries. New size: " + cache.size());
    }
    
    // Cleanup expired entries every 5 minutes
    @Scheduled(fixedRate = 300000) 
    public void cleanupExpiredEntries() {
        int sizeBefore = cache.size();
        cache.entrySet().removeIf(entry -> entry.getValue().isExpired());
        int sizeAfter = cache.size();
        
        if (sizeBefore != sizeAfter) {
            System.out.println("🧹 Removed " + (sizeBefore - sizeAfter) + " expired cache entries");
        }
    }
    
    // Get cache statistics
    public Map<String, Object> getCacheStats() {
        long expiredCount = cache.values().stream()
            .mapToLong(cached -> cached.isExpired() ? 1 : 0)
            .sum();
            
        return Map.of(
            "total_entries", cache.size(),
            "expired_entries", expiredCount,
            "valid_entries", cache.size() - expiredCount,
            "max_size", MAX_CACHE_SIZE,
            "ttl_minutes", CACHE_TTL_MINUTES
        );
    }
    
    // Clear all cache (for testing/debugging)
    public void clearCache() {
        cache.clear();
        System.out.println("🗑️ Cache cleared");
    }
    
    private static class CachedResult {
        final CompilationResult result;
        final long timestamp;
        
        CachedResult(CompilationResult result) {
            this.result = result;
            this.timestamp = System.currentTimeMillis();
        }
        
        boolean isExpired() {
            return System.currentTimeMillis() - timestamp > TimeUnit.MINUTES.toMillis(CACHE_TTL_MINUTES);
        }
    }
}