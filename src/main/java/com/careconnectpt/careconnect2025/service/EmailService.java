package com.careconnectpt.careconnect2025.service;


public interface EmailService {

    /**
     * Sends a plain-text e-mail.
     *
     * @param to           recipient address
     * @param subject      subject line
     * @param body         plain-text body
     */
    void sendTextMail(String to, String subject, String body);

    /**
     * Sends an HTML e-mail (optional convenience).
     */
    void sendHtmlMail(String to, String subject, String html);
}
