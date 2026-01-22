package io.scade.swift4j;

public class SwiftError extends Exception {

    public SwiftError(String message) {
        super(message);
    }

    public SwiftError(String message, Throwable cause) {
        super(message, cause);
    }

    public SwiftError(Throwable cause) {
        super(cause);
    }
}