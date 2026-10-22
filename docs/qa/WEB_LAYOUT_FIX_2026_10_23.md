# Web layout regression

Symptom: desktop navigation inside a centered 520px frame; content squeezed into ~276px with dark margins.

Cause: FluentTalkApp unconditionally applied ResponsiveContentWrapper. AppShell used window MediaQuery rather than its local constraints. Earlier design captures used MaterialApp.router directly and bypassed the production root.

Fix: real accounts use the full viewport; only explicit demo mode retains the phone preview frame. Shell chooses desktop navigation from LayoutBuilder constraints. The design test now mounts FluentTalkApp and asserts actual content width at 390, 886, 1280 and 1440px, including 200% text. Demo mobile navigation remains covered.

Visual checks: docs/qa/ui/academic-home-886.png and academic-home-1440.png use fixture data, rendered through the actual application root. They do not represent provider or real-account data verification.
