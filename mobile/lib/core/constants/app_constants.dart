class AppConstants {
  // ─── Base URL ─────────────────────────────────────────────────────────────
  // Flutter Web → backend runs at localhost:8080
  // Android emulator → use 10.0.2.2:8080
  // Real device → use machine's LAN IP e.g. 192.168.1.x:8080
  static const String baseUrl = 'https://skillforge-03ys.onrender.com/api/v1';

  // ─── Auth  (AuthController → @RequestMapping("/api/v1/auth")) ─────────────
  static const String loginUrl        = '$baseUrl/auth/login';
  static const String registerUrl     = '$baseUrl/auth/register';
  static const String refreshUrl      = '$baseUrl/auth/refresh';
  static const String profileUrl      = '$baseUrl/auth/me';
  static const String otpRequestUrl   = '$baseUrl/auth/otp/request';
  static const String otpLoginUrl     = '$baseUrl/auth/otp/login';
  static const String resetPasswordUrl = '$baseUrl/auth/password/reset';
  static const String googleLoginUrl  = '$baseUrl/auth/google/login';

  // ─── Courses (CourseController) ───────────────────────────────────────────
  static const String coursesUrl      = '$baseUrl/courses';         // GET list, POST create
  static const String categoriesUrl   = '$baseUrl/categories';
  static const String wishlistUrl     = '$baseUrl/wishlist';

  // ─── Enrollments (EnrollmentController) ──────────────────────────────────
  // ⚠️  Backend: POST /api/v1/enrollments  (body: { courseId })
  // NOT /api/v1/courses/{id}/enroll — that does NOT exist
  static const String enrollmentsUrl  = '$baseUrl/enrollments';

  // ─── Learning (LearningController) ───────────────────────────────────────
  static const String notesUrl        = '$baseUrl/notes';
  static const String bookmarksUrl    = '$baseUrl/bookmarks';

  // ─── AI (AiController) ────────────────────────────────────────────────────
  // Flow: POST /ai/sessions → get sessionId
  //       POST /ai/sessions/{sessionId}/messages → send question, get answer
  //       GET  /ai/sessions/{sessionId}/history  → message history
  static const String aiSessionsUrl      = '$baseUrl/ai/sessions';
  static const String aiRecommendations  = '$baseUrl/ai/recommendations';
  // lessonId-specific: '$baseUrl/ai/lessons/{lessonId}/generate-quiz'
  // lessonId-specific: '$baseUrl/ai/lessons/{lessonId}/generate-notes'
  static const String aiRoadmapUrl       = '$baseUrl/ai/roadmap';
  static const String aiAtsMatchUrl      = '$baseUrl/ai/ats-resume-match';
  static const String aiCodeReviewUrl    = '$baseUrl/ai/code-review';

  // ─── Assessment (AssessmentController) ───────────────────────────────────
  // courseId-specific: '$baseUrl/courses/{courseId}/assessments'
  // submissionId: '$baseUrl/assessments/{assessmentId}/submissions'
  static const String assessmentsBase    = '$baseUrl/assessments';
  static const String submissionsBase    = '$baseUrl/submissions';

  // ─── Certificate (CertificateController) ─────────────────────────────────
  // enrollmentId-specific: '$baseUrl/certificates/enrollments/{enrollmentId}'
  // verificationCode: '$baseUrl/certificates/verify/{verificationCode}'
  static const String certificatesBase   = '$baseUrl/certificates';

  // ─── Live Classes (LiveClassController) ──────────────────────────────────
  // courseId-specific: '$baseUrl/courses/{courseId}/live-sessions'
  // sessionId-specific: '$baseUrl/live-sessions/{sessionId}/join'
  static const String liveSessionsBase   = '$baseUrl/live-sessions';
  static const String mentoringUrl       = '$baseUrl/mentoring';
  static const String calendarExportUrl  = '$baseUrl/calendar/export';

  // ─── Community (CommunityController) ─────────────────────────────────────
  static const String forumPostsUrl      = '$baseUrl/forum/posts';
  static const String announcementsUrl   = '$baseUrl/announcements';
  static const String groupsUrl          = '$baseUrl/groups';
  static const String leaderboardUrl     = '$baseUrl/leaderboard';
  static const String achievementsUrl    = '$baseUrl/achievements';

  // ─── Career (CareerController) ────────────────────────────────────────────
  static const String jobsUrl            = '$baseUrl/jobs';
  static const String resumesUrl         = '$baseUrl/resumes';
  static const String mockInterviewsUrl  = '$baseUrl/mock-interviews';

  // ─── Playground (PlaygroundController) ───────────────────────────────────
  static const String playgroundRunUrl   = '$baseUrl/playground/run';
  static const String playgroundTestUrl  = '$baseUrl/playground/test-runner';

  // ─── Mobile (MobileController) ────────────────────────────────────────────
  static const String registerDeviceUrl      = '$baseUrl/mobile/devices';
  static const String studentDashboardUrl    = '$baseUrl/mobile/student/dashboard';
  static const String instructorDashboardUrl = '$baseUrl/mobile/instructor/dashboard';
  static const String notificationsUrl       = '$baseUrl/mobile/notifications';

  // ─── Analytics (AnalyticsController) ─────────────────────────────────────
  static const String logActivityUrl  = '$baseUrl/analytics/logs';

  // ─── Payments (PaymentController) ─────────────────────────────────────────
  static const String checkoutUrl     = '$baseUrl/orders/checkout';
  static const String subscriptionPlansUrl = '$baseUrl/subscriptions/plans';
  static const String couponsUrl      = '$baseUrl/coupons';

  // ─── Storage (StorageController) ─────────────────────────────────────────
  static const String uploadUrl       = '$baseUrl/storage/upload';

  // ─── App Meta ─────────────────────────────────────────────────────────────
  static const String appName    = 'SkillForge';
  static const String appVersion = '1.0.0';

  // ─── Secure Storage Keys ─────────────────────────────────────────────────
  static const String tokenKey        = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userEmailKey    = 'user_email';
  static const String userNameKey     = 'user_name';
  static const String userRoleKey     = 'user_role';
  static const String aiSessionIdKey  = 'ai_session_id';
}
