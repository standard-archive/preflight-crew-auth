# PreFlight Crew

A secure login gateway restricted to WeThinkCode student emails, built for the WeThinkCode Mobile Development elective (Track 2: Firebase Authentication).

## Problem

Peer accountability only works if you trust who you are talking to. PreFlight Crew is the secure front door for a small student "crew" to share progress and keep each other accountable, restricted to verified student.wethinkcode.co.za accounts so it cannot be joined by outsiders.

## Features

- Email/password signup restricted to @student.wethinkcode.co.za addresses
- Mandatory email verification before accessing the app
- Password reset flow with a real emailed reset link
- Profile screen showing account email and join date
- Crew-join placeholder demonstrating the intended accountability feature
- Auth-state-driven routing (login, verify-email, and home screens swap automatically)

## Tech Stack

- Flutter (web target, Chrome)
- Dart
- Firebase Authentication (firebase_auth)
- Firebase Core (firebase_core)
- StreamBuilder-driven auth state routing (userChanges for live-reload verification)

## Run It

    flutter pub get
    flutter run -d chrome

## Screenshots

(screenshots go in the /screenshots folder - see below)

## Wiki

Full project documentation and a session-by-session development log are available on the [project wiki](https://github.com/lichumestandard-sudo/preflight-crew-auth/wiki).

