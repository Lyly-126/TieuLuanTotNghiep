package com.tieuluan.backend.controller;

import com.tieuluan.backend.util.JwtUtil;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

/**
 * 🔧 DEBUG Controller - Kiểm tra authentication
 * XÓA SAU KHI DEBUG XONG
 */
@RestController
@RequestMapping("/api/debug")
@CrossOrigin(origins = "*")
public class DebugController {

    @Autowired
    private JwtUtil jwtUtil;

    /**
     * GET /api/debug/auth
     * Kiểm tra authentication hiện tại
     */
    @GetMapping("/auth")
    public ResponseEntity<?> checkAuth(@RequestHeader(value = "Authorization", required = false) String authHeader) {
        try {
            Authentication auth = SecurityContextHolder.getContext().getAuthentication();

            String tokenInfo = "No token";
            String role = "Unknown";
            Long userId = null;

            if (authHeader != null && authHeader.startsWith("Bearer ")) {
                String token = authHeader.substring(7);
                try {
                    role = jwtUtil.extractRole(token);
                    userId = jwtUtil.getUserIdFromToken(token);
                    tokenInfo = "Valid token";
                } catch (Exception e) {
                    tokenInfo = "Invalid token: " + e.getMessage();
                }
            }

            return ResponseEntity.ok(Map.of(
                    "authenticated", auth != null && auth.isAuthenticated(),
                    "principal", auth != null ? auth.getPrincipal().toString() : "null",
                    "authorities", auth != null ? auth.getAuthorities().toString() : "[]",
                    "tokenInfo", tokenInfo,
                    "role", role,
                    "userId", userId != null ? userId : "null"
            ));
        } catch (Exception e) {
            return ResponseEntity.ok(Map.of(
                    "error", e.getMessage(),
                    "authenticated", false
            ));
        }
    }

    /**
     * GET /api/debug/public
     * Endpoint public - không cần auth
     */
    @GetMapping("/public")
    public ResponseEntity<?> publicEndpoint() {
        return ResponseEntity.ok(Map.of(
                "message", "This is a public endpoint",
                "status", "OK"
        ));
    }
}