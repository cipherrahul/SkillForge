# Design.md

# UI/UX Design System

**Project:** SkillForge (Working Name)

**Design Philosophy:** Minimal • Modern • Professional • White First • Mobile First

---

# 1. Design Vision

The application should feel like a combination of:

- Notion (Clean UI)
- Linear (Modern Experience)
- Coursera (Professional Learning)
- Duolingo (Engagement)
- Stripe Dashboard (Premium Feel)

Every screen should be simple, intuitive, and focused on helping users learn without distractions.

---

# 2. Design Principles

- White-first interface
- Minimal visual clutter
- Content-focused layouts
- Consistent spacing
- Fast interactions
- Accessible design
- Mobile-first responsiveness
- Reusable components
- Smooth animations
- Premium appearance

---

# 3. Color System

## Primary Colors

| Purpose | Color |
|----------|---------|
| Primary | #2563EB |
| Primary Hover | #1D4ED8 |
| Primary Light | #DBEAFE |

---

## Background Colors

| Purpose | Color |
|----------|---------|
| Main Background | #FFFFFF |
| Secondary Background | #F8FAFC |
| Card Background | #FFFFFF |
| Section Background | #F1F5F9 |

---

## Text Colors

| Purpose | Color |
|----------|---------|
| Heading | #0F172A |
| Body | #334155 |
| Secondary | #64748B |
| Disabled | #CBD5E1 |

---

## Status Colors

Success → #22C55E

Warning → #F59E0B

Error → #EF4444

Info → #0EA5E9

---

# 4. Typography

## Font Family

Primary

```
Inter
```

Fallback

```
Roboto

System Sans
```

---

## Font Sizes

| Element | Size |
|----------|------|
| H1 | 32px |
| H2 | 28px |
| H3 | 24px |
| H4 | 20px |
| H5 | 18px |
| Body | 16px |
| Caption | 14px |
| Small | 12px |

---

# 5. Spacing System

Use an 8-point grid.

```
4

8

16

24

32

48

64
```

Never use random spacing.

---

# 6. Border Radius

Buttons

12px

Cards

16px

Dialogs

20px

Bottom Sheets

24px

Avatars

Circular

---

# 7. Shadow System

Use soft shadows only.

Never use heavy shadows.

Cards should appear elevated but lightweight.

---

# 8. Iconography

Use Material Symbols or Lucide Icons.

Rules

- Consistent size
- Rounded style
- Minimal outlines
- No mixed icon packs

---

# 9. Navigation

## Student App

Bottom Navigation

```
🏠 Home

📚 My Learning

🔍 Explore

💬 Community

👤 Profile
```

---

## Instructor App

Bottom Navigation

```
🏠 Dashboard

📖 Courses

🎥 Live

📊 Analytics

👤 Profile
```

---

## Admin Dashboard

Sidebar Navigation

```
Dashboard

Users

Courses

Institutions

Payments

Analytics

Reports

Settings
```

---

# 10. Dashboard Design

Student Dashboard

Sections

- Continue Learning
- Recommended Courses
- Upcoming Live Classes
- Weekly Goals
- Certificates
- Internship Opportunities
- Community Updates

Instructor Dashboard

Sections

- Revenue
- Students
- Live Sessions
- Pending Reviews
- Course Performance
- Recent Enrollments

---

# 11. Component Library

Reusable Components

- Primary Button
- Secondary Button
- Icon Button
- Card
- Dialog
- Bottom Sheet
- Snackbar
- Search Bar
- Tabs
- Progress Bar
- Course Card
- Instructor Card
- Lesson Tile
- Assignment Card
- Certificate Card
- Empty State
- Error State
- Skeleton Loader

---

# 12. Forms

Rules

- Floating labels
- Inline validation
- Clear error messages
- Password visibility toggle
- Large touch targets
- Auto focus where appropriate

---

# 13. Course Card Design

Must display

- Thumbnail
- Course Title
- Instructor
- Rating
- Duration
- Students Enrolled
- Price
- Difficulty
- Progress (if enrolled)

---

# 14. Animations

Use subtle animations only.

Examples

- Page transitions
- Card hover
- Button ripple
- Progress updates
- Loading shimmer
- Bottom sheet slide
- Fade transitions

Animation duration

200–300 ms

---

# 15. Mobile UX Guidelines

- One-handed navigation
- Large touch targets (48px minimum)
- Bottom navigation for primary actions
- Sticky CTA buttons where needed
- Swipe gestures for lists
- Offline-friendly UI
- Fast loading states

---

# 16. Accessibility

Support

- Screen readers
- Keyboard navigation (Web)
- High contrast text
- Scalable fonts
- Color-blind friendly indicators
- Focus states
- Semantic labels

---

# 17. Empty & Error States

Every screen should provide meaningful feedback.

Examples

### Empty

"No courses enrolled yet. Start exploring courses."

### Error

"Something went wrong. Please try again."

### Offline

"You are offline. Previously downloaded content is still available."

---

# 18. Design Consistency Rules

Always

- Use reusable components
- Maintain consistent spacing
- Follow typography scale
- Keep button styles consistent
- Use the defined color palette
- Optimize for mobile first

Never

- Mix different button styles
- Use random colors
- Overuse animations
- Create inconsistent layouts
- Add unnecessary UI elements

---

# 19. Branding

Visual Identity

- Clean
- Professional
- Trustworthy
- Modern
- Career-focused
- Technology-driven

The UI should communicate confidence and simplicity while keeping learning at the center.

---

# 20. Future Enhancements

- Dark Mode
- Dynamic Themes (Institution Branding)
- Glassmorphism for premium sections
- AI-powered personalized dashboard
- Interactive learning widgets
- Achievement badges and gamification
- Micro-interactions across the app

---

# Design Goal

Every user should be able to complete any major task—finding a course, joining a live class, publishing content, or viewing analytics—in **three taps or fewer** whenever practical.

The experience should feel fast, intuitive, and consistent across Android, iOS, and Web.

---

**Document Status:** Draft v1.0

**References:**
- `PRD.md`
- `Architecture.md`
- `Rules.md`
- `Phases.md`