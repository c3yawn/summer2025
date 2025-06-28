package com.careconnectpt.careconnect2025.dto;

import com.careconnectpt.careconnect2025.security.Role;
import lombok.Builder;

@Builder
public record LoginResponse(long id, String email, Role role, String token) {

	public static LoginResponseBuilder builder() {
        return new LoginResponseBuilder();
    }

    public static class LoginResponseBuilder {
        private long id;
        private String email;
        private Role role;
        private String token;

        public LoginResponseBuilder id(long id) {
            this.id = id;
            return this;
        }

        public LoginResponseBuilder email(String email) {
            this.email = email;
            return this;
        }

        public LoginResponseBuilder role(Role role) {
            this.role = role;
            return this;
        }

        public LoginResponseBuilder token(String token) {
            this.token = token;
            return this;
        }

        public LoginResponse build() {
            return new LoginResponse(id, email, role, token);
        }
    }
}