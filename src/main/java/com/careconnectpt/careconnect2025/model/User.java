package com.careconnectpt.careconnect2025.model;

import org.springframework.http.HttpStatus;

import com.careconnectpt.careconnect2025.security.Role;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
@Entity
@Table(name = "users")
public class User {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(unique = true, nullable = false)
    private String email;

	@Column(name = "password_hash", nullable = false)
    private String password;

    @Enumerated(EnumType.STRING)
	@Column(nullable = false)
    private com.careconnectpt.careconnect2025.security.Role role;
    
    @Column(nullable = false)
	@Builder.Default
    private boolean emailVerified = false;

	public Long getId() {
		return id;
	}

	public void setId(Long id) {
		this.id = id;
	}

	public String getEmail() {
		return email;
	}

	public void setEmail(String email) {
		this.email = email;
	}

	public String getPassword() {
		return password;
	}

	public void setPassword(String password) {
		this.password = password;
	}

	public com.careconnectpt.careconnect2025.security.Role getRole() {
		return role;
	}

	public void setRole(com.careconnectpt.careconnect2025.security.Role role) {
		this.role = role;
	}

	public boolean isEmailVerified() {
		return emailVerified;
	}

	public void setEmailVerified(boolean emailVerified) {
		this.emailVerified = emailVerified;
	}
	
	

}