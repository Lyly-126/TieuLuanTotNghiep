package com.tieuluan.backend.config;

import lombok.RequiredArgsConstructor;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.config.annotation.method.configuration.EnableMethodSecurity;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.CorsConfigurationSource;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;

import java.util.Arrays;

@Configuration
@EnableWebSecurity
@EnableMethodSecurity
@RequiredArgsConstructor
public class SecurityConfig {

    private final JwtAuthenticationFilter jwtAuthenticationFilter;

    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }

    @Bean
    public CorsConfigurationSource corsConfigurationSource() {
        CorsConfiguration configuration = new CorsConfiguration();
        configuration.setAllowedOriginPatterns(Arrays.asList("*"));
        configuration.setAllowedMethods(Arrays.asList("GET", "POST", "PUT", "DELETE", "OPTIONS", "PATCH"));
        configuration.setAllowedHeaders(Arrays.asList("*"));
        configuration.setAllowCredentials(true);
        configuration.setExposedHeaders(Arrays.asList("Authorization", "Content-Type"));
        configuration.setMaxAge(3600L);

        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        source.registerCorsConfiguration("/**", configuration);
        return source;
    }

    @Bean
    public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
        http
                .cors(cors -> cors.configurationSource(corsConfigurationSource()))
                .csrf(csrf -> csrf.disable())
                .sessionManagement(session -> session
                        .sessionCreationPolicy(SessionCreationPolicy.STATELESS))

                .authorizeHttpRequests(auth -> auth
                        // ========== PUBLIC ENDPOINTS ==========
                        .requestMatchers("/api/users/register", "/api/users/login").permitAll()
                        .requestMatchers("/api/otp/**", "/api/auth/forgot-password/**").permitAll()
                        .requestMatchers("/api/payment/vnpay/return", "/api/payment/vnpay/callback").permitAll()
                        .requestMatchers("/api/policies", "/api/policies/{id}").permitAll()
                        .requestMatchers("/api/study-packs", "/api/study-packs/{id}").permitAll()
                        .requestMatchers("/api/flashcards", "/api/flashcards/{id}").permitAll()
                        .requestMatchers("/api/flashcards/category/**").permitAll()
                        .requestMatchers("/api/flashcards/random").permitAll()
                        .requestMatchers("/api/flashcards/search").permitAll()
                        .requestMatchers("/api/flashcards/ai/**").permitAll()

                        // ========== ADMIN ONLY ==========
                        .requestMatchers("/api/admin/**").hasRole("ADMIN")
                        .requestMatchers("/api/users/admin/**").hasRole("ADMIN")
                        .requestMatchers("/api/policies/admin/**").hasRole("ADMIN")
                        .requestMatchers("/api/flashcards/admin/**").hasRole("ADMIN")
                        .requestMatchers("/api/study-packs/admin/**").hasRole("ADMIN")

                        // ========== ALL AUTHENTICATED USERS ==========
                        .requestMatchers("/api/payment/**").authenticated()
                        .requestMatchers("/api/users/profile").authenticated()
                        .requestMatchers("/api/users/change-password").authenticated()
                        .requestMatchers("/api/users/{id}").authenticated()
                        .requestMatchers("/api/users/email/**").authenticated()
                        .requestMatchers("/api/users/{id}/profile").authenticated()
                        .requestMatchers("/api/users/delete").authenticated()

                        // ========== ✅ CLASSES - SPECIFIC PATTERNS FIRST ==========
                        // CLASS MEMBERS - SPECIFIC ENDPOINTS (MUST BE BEFORE GENERAL PATTERNS)
                        .requestMatchers("/api/classes/{classId}/members/pending").hasAnyRole("TEACHER", "ADMIN")
                        .requestMatchers("/api/classes/{classId}/members/{userId}/approve").hasAnyRole("TEACHER", "ADMIN")
                        .requestMatchers("/api/classes/{classId}/members/{userId}/reject").hasAnyRole("TEACHER", "ADMIN")
                        .requestMatchers("/api/classes/{classId}/members/add").hasAnyRole("TEACHER", "ADMIN")
                        .requestMatchers("/api/classes/{classId}/members/{userId}").hasAnyRole("TEACHER", "ADMIN")

                        // THEN GENERAL MEMBER ENDPOINT (for viewing - all authenticated users)
                        .requestMatchers("/api/classes/*/members").authenticated()

                        // CLASS MANAGEMENT - TEACHER/ADMIN ONLY
                        .requestMatchers("/api/classes/create").hasAnyRole("TEACHER", "ADMIN")
                        .requestMatchers("/api/classes/my-classes").hasAnyRole("TEACHER", "ADMIN")
                        .requestMatchers("/api/classes/{id}/update").hasAnyRole("TEACHER", "ADMIN")
                        .requestMatchers("/api/classes/{id}/delete").hasAnyRole("TEACHER", "ADMIN")
                        .requestMatchers("/api/classes/{id}/regenerate-invite-code").hasAnyRole("TEACHER", "ADMIN")
                        .requestMatchers("/api/classes/{id}/category-count").hasAnyRole("TEACHER", "ADMIN")
                        .requestMatchers("/api/classes/admin/**").hasRole("ADMIN")

                        // ✅ CLASS PUBLIC ACCESS - ALL AUTHENTICATED USERS
                        .requestMatchers("/api/classes/search").authenticated()
                        .requestMatchers("/api/classes/{id}/membership-status").authenticated()
                        .requestMatchers("/api/classes/join").authenticated()
                        .requestMatchers("/api/classes/{id}/join").authenticated()
                        .requestMatchers("/api/classes/{id}/leave").authenticated()
                        .requestMatchers("/api/classes/joined").authenticated()

                        // CLASS DETAIL (MUST BE LAST AMONG CLASS ENDPOINTS)
                        .requestMatchers("/api/classes/{id}").authenticated()

                        // ========== ✅ CATEGORIES - ALL AUTHENTICATED ==========
                        .requestMatchers("/api/categories/search").authenticated()
                        .requestMatchers("/api/categories/saved").authenticated()  // ✅ THÊM DÒNG NÀY
                        .requestMatchers("/api/categories/public").authenticated()
                        .requestMatchers("/api/categories/{id}/save").authenticated()

                        // Static resources
                        .requestMatchers("/audio/**").permitAll()

                        // All other requests require authentication
                        .anyRequest().authenticated()
                )
                .addFilterBefore(jwtAuthenticationFilter, UsernamePasswordAuthenticationFilter.class);

        return http.build();
    }
}