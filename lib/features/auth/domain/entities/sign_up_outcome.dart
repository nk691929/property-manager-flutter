enum SignUpOutcome {
  /// Session created immediately (email confirmation disabled).
  signedIn,

  /// The user must confirm their email before signing in.
  confirmationRequired,
}
