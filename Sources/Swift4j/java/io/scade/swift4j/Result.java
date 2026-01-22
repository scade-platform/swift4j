package io.scade.swift4j;

import java.util.Objects;
import java.util.function.Function;

/**
 * Java equivalent of Swift's Result<Success, Failure: Error>.
 *
 * @param <T> Success value type
 * @param <E> Error type (Throwable is the closest analogue to Swift Error)
 */
public final class Result<T, E extends Throwable> {

    private final T value;
    private final E error;

    private Result(T value, E error) {
        this.value = value;
        this.error = error;
    }

    /** Create a success result. Equivalent to Swift: .success(value) */
    public static <T, E extends Throwable> Result<T, E> ok(T value) {
        return new Result<>(value, null);
    }

    /** Create a failure result. Equivalent to Swift: .failure(error) */
    public static <T, E extends Throwable> Result<T, E> err(E error) {
        return new Result<>(null, Objects.requireNonNull(error, "error"));
    }

    public boolean isOk() {
        return error == null;
    }

    public boolean isErr() {
        return error != null;
    }

    /** Returns the success value or null if this is an error. */
    public T getOrNull() {
        return value;
    }

    /** Returns the error or null if this is a success. */
    public E errorOrNull() {
        return error;
    }

    /**
     * Returns the success value or throws the stored error.
     * Similar spirit to Swift's `try result.get()`.
     */
    public T getOrThrow() throws E {
        if (error != null) throw error;
        return value;
    }

    /** Returns value if ok, otherwise fallback. */
    public T getOrElse(Function<? super E, ? extends T> fallback) {
        Objects.requireNonNull(fallback, "fallback");
        return (error == null) ? value : fallback.apply(error);
    }

    /** Transform the success value. Equivalent to Swift: result.map { ... } */
    public <U> Result<U, E> map(Function<? super T, ? extends U> f) {
        Objects.requireNonNull(f, "f");
        return (error == null) ? Result.ok(f.apply(value)) : Result.err(error);
    }

    /** Transform the error value. Equivalent to Swift: result.mapError { ... } */
    public <F extends Throwable> Result<T, F> mapError(Function<? super E, ? extends F> f) {
        Objects.requireNonNull(f, "f");
        return (error == null) ? Result.ok(value) : Result.err(f.apply(error));
    }

    /** Flat-map success. Equivalent to Swift: result.flatMap { ... } */
    public <U> Result<U, E> flatMap(Function<? super T, Result<U, E>> f) {
        Objects.requireNonNull(f, "f");
        return (error == null) ? Objects.requireNonNull(f.apply(value), "flatMap returned null")
                               : Result.err(error);
    }

    /**
     * Fold into a single value.
     * Equivalent idea to Swift: switch over .success/.failure.
     */
    public <R> R fold(Function<? super T, ? extends R> onOk,
                      Function<? super E, ? extends R> onErr) {
        Objects.requireNonNull(onOk, "onOk");
        Objects.requireNonNull(onErr, "onErr");
        return (error == null) ? onOk.apply(value) : onErr.apply(error);
    }

    @Override
    public String toString() {
        return (error == null) ? "Result.ok(" + value + ")" : "Result.err(" + error + ")";
    }

    @Override
    public boolean equals(Object o) {
        if (!(o instanceof Result<?, ?> other)) return false;
        return Objects.equals(this.value, other.value) && Objects.equals(this.error, other.error);
    }

    @Override
    public int hashCode() {
        return Objects.hash(value, error);
    }
}