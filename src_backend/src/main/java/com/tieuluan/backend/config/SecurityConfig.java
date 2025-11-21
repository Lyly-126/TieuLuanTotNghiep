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
import java.util.List;

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
                        // Public endpoints
                        .requestMatchers("/api/users/register", "/api/users/login").permitAll()
                        .requestMatchers("/api/otp/**", "/api/auth/forgot-password/**").permitAll()
                        .requestMatchers("/api/payment/vnpay/return").permitAll()
                        .requestMatchers("/api/payment/vnpay/callback").permitAll()

                        // Payment - User endpoints
                        .requestMatchers("/api/payment/**").hasAnyRole("USER", "ADMIN")

                        // Study Packs - PUBLIC
                        .requestMatchers("/api/study-packs", "/api/study-packs/{id}").permitAll()
                        .requestMatchers("/api/study-packs/admin/**").hasRole("ADMIN")

                        // Flashcard - Public endpoints
                        .requestMatchers("/api/flashcards", "/api/flashcards/{id}").permitAll()
                        .requestMatchers("/api/flashcards/category/**").permitAll()
                        .requestMatchers("/api/flashcards/random").permitAll()
                        .requestMatchers("/api/flashcards/search").permitAll()

                        // ✅ AI Flashcard - User & Admin endpoints (REQUIRES AUTH)
                        .requestMatchers("/api/flashcards/ai/generate").permitAll()
                        .requestMatchers("/api/flashcards/ai/batch").permitAll()
                        .requestMatchers("/api/flashcards/ai/status").permitAll()
                        .requestMatchers("/api/flashcards/ai/health").permitAll()

                        // Flashcard - Admin endpoints
                        .requestMatchers("/api/flashcards/admin/**").hasRole("ADMIN")

                        // Policy endpoints
                        .requestMatchers("/api/policies", "/api/policies/{id}").permitAll()

                        // Admin endpoints
                        .requestMatchers("/api/admin/**").hasRole("ADMIN")
                        .requestMatchers("/api/policies/admin/**").hasRole("ADMIN")
                        .requestMatchers("/api/users/admin/**").hasRole("ADMIN")

                        // User endpoints
                        .requestMatchers("/api/users/**").hasAnyRole("USER", "ADMIN")

                        // Static resources (for serving audio files)
                        .requestMatchers("/api/tts/**").permitAll()

                        // All other requests require authentication
                        .anyRequest().authenticated()
                )

                .addFilterBefore(jwtAuthenticationFilter, UsernamePasswordAuthenticationFilter.class);

        return http.build();
    }
}