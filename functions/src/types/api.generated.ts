/**
 * Auto-generated TypeScript types matching OpenAPI 3.0.3 specification.
 * Generated from docs/api/openapi.yaml via openapi-typescript.
 */

export interface paths {
  "/api/v1/users/{user_id}/public-profile": {
    get: operations["getPublicProfile"];
  };
  "/api/v1/users/{user_id}/reviews": {
    get: operations["getUserRevealedReviews"];
  };
  "/api/v1/users/me": {
    delete: operations["deleteCurrentUser"];
  };
  "/api/v1/search": {
    get: operations["searchProfiles"];
  };
  "/api/v1/swaps/request": {
    post: operations["createSwapRequest"];
  };
  "/api/v1/swaps/{swap_id}/status": {
    patch: operations["updateSwapStatus"];
  };
  "/api/v1/swaps/{swap_id}/qr-token": {
    get: operations["getSwapQrToken"];
  };
  "/api/v1/meetings/validate-qr": {
    post: operations["validateMeetingQr"];
  };
  "/api/v1/swaps/{swap_id}/messages": {
    get: operations["getSwapMessages"];
    post: operations["sendSwapMessage"];
  };
  "/api/v1/swaps/{swap_id}/reviews": {
    post: operations["submitSwapReview"];
  };
}

export interface components {
  schemas: {
    ApiError: {
      code: string;
      message: string;
      status: number;
      details?: Record<string, unknown> | null;
    };
    ValidationError: {
      code: string;
      message: string;
      status: number;
      errors: Array<{
        field: string;
        message: string;
      }>;
    };
    SkillItem: {
      skill_id: string;
      name: string;
      category: string;
      proficiency_level?: "BEGINNER" | "INTERMEDIATE" | "ADVANCED" | "EXPERT";
    };
    PublicProfileResponse: {
      user_id: string;
      basic_info: {
        display_name: string;
        avatar_url?: string | null;
        bio?: string | null;
      };
      location: {
        zone_name: string;
        distance_km?: number | null;
      };
      reputation: {
        average_score: number;
        total_reviews: number;
        punctuality_score: number;
      };
      skills: {
        offered: components["schemas"]["SkillItem"][];
        desired: components["schemas"]["SkillItem"][];
      };
      availability_status: "AVAILABLE" | "UNAVAILABLE";
      metadata: {
        joined_at: string;
      };
    };
    PaginatedReviewsResponse: {
      data: components["schemas"]["ReviewItem"][];
      pagination: components["schemas"]["PaginationMetadata"];
    };
    ReviewItem: {
      review_id: string;
      swap_id: string;
      reviewer: {
        user_id: string;
        display_name: string;
        avatar_url?: string | null;
      };
      rating: number;
      comment: string;
      skill_confirmed: boolean;
      created_at: string;
    };
    PaginationMetadata: {
      page: number;
      limit: number;
      total: number;
      total_pages: number;
    };
    SearchProfilesResponse: {
      data: components["schemas"]["SearchProfileSummary"][];
      pagination: components["schemas"]["PaginationMetadata"];
    };
    SearchProfileSummary: {
      user_id: string;
      display_name: string;
      avatar_url?: string | null;
      bio?: string | null;
      zone_name?: string;
      distance_km?: number | null;
      availability_status: "AVAILABLE" | "UNAVAILABLE";
      reputation: {
        average_score: number;
        total_reviews: number;
      };
      offered_skills: components["schemas"]["SkillItem"][];
      desired_skills: components["schemas"]["SkillItem"][];
    };
    CreateSwapProposalRequest: {
      target_user_id: string;
      offered_skill_id: string;
      requested_skill_id: string;
      initial_message: string;
    };
    SwapProposalCreatedResponse: {
      swap_id: string;
      requester_id: string;
      receiver_id: string;
      offered_skill_id: string;
      requested_skill_id: string;
      status: "PENDING";
      created_at: string;
    };
    UpdateSwapStatusRequest: {
      action: "ACCEPT" | "REJECT" | "SCHEDULE" | "CANCEL";
      scheduled_at?: string;
      meeting_location?: string;
      cancellation_reason?: string | null;
    };
    SwapDetailResponse: {
      swap_id: string;
      requester_id: string;
      receiver_id: string;
      offered_skill_id: string;
      requested_skill_id: string;
      status: "PENDING" | "MATCHED" | "SCHEDULED" | "COMPLETED" | "CANCELLED" | "REJECTED";
      scheduled_at?: string | null;
      completed_at?: string | null;
      meeting_location?: string | null;
      created_at: string;
      updated_at: string;
    };
    QrTokenResponse: {
      swap_id: string;
      totp_token: string;
      expires_in_seconds: number;
      refresh_interval_seconds: number;
      server_timestamp: string;
    };
    ValidateMeetingQrRequest: {
      swap_id: string;
      totp_token: string;
      latitude: number;
      longitude: number;
    };
    ValidateMeetingQrResponse: {
      success: boolean;
      swap_id: string;
      status: "COMPLETED";
      completed_at: string;
      message: string;
    };
    ChatMessageResponse: {
      message_id: string;
      swap_id: string;
      sender_id: string;
      message_type: "TEXT" | "QUICK_REPLY" | "ACTION_WIDGET";
      content: string;
      widget_payload?: Record<string, unknown> | null;
      is_system: boolean;
      created_at: string;
    };
    ChatMessageListResponse: {
      swap_id: string;
      messages: components["schemas"]["ChatMessageResponse"][];
    };
    SendMessageRequest: {
      message_type: "TEXT" | "QUICK_REPLY" | "ACTION_WIDGET";
      content: string;
      widget_payload?: Record<string, unknown> | null;
    };
    SubmitReviewRequest: {
      rating: number;
      comment: string;
      skill_confirmed: boolean;
    };
    ReviewSubmissionResponse: {
      review_id: string;
      swap_id: string;
      status: "SUBMITTED";
      is_revealed: boolean;
      created_at: string;
      message: string;
    };
  };
}

export interface operations {
  getPublicProfile: {
    parameters: {
      path: { user_id: string };
      query?: { requester_lat?: number; requester_lng?: number };
    };
    responses: {
      200: { content: { "application/json": components["schemas"]["PublicProfileResponse"] } };
      400: { content: { "application/json": components["schemas"]["ApiError"] } };
      401: { content: { "application/json": components["schemas"]["ApiError"] } };
      404: { content: { "application/json": components["schemas"]["ApiError"] } };
    };
  };
  getUserRevealedReviews: {
    parameters: {
      path: { user_id: string };
      query?: { page?: number; limit?: number };
    };
    responses: {
      200: { content: { "application/json": components["schemas"]["PaginatedReviewsResponse"] } };
      400: { content: { "application/json": components["schemas"]["ApiError"] } };
      401: { content: { "application/json": components["schemas"]["ApiError"] } };
      404: { content: { "application/json": components["schemas"]["ApiError"] } };
    };
  };
  deleteCurrentUser: {
    responses: {
      200: { content: { "application/json": { success: boolean; message: string } } };
      401: { content: { "application/json": components["schemas"]["ApiError"] } };
    };
  };
  searchProfiles: {
    parameters: {
      query?: {
        query?: string;
        category?: string;
        skill_id?: string;
        h3_index?: string;
        radius_km?: number;
        page?: number;
        limit?: number;
      };
    };
    responses: {
      200: { content: { "application/json": components["schemas"]["SearchProfilesResponse"] } };
      400: { content: { "application/json": components["schemas"]["ApiError"] } };
      401: { content: { "application/json": components["schemas"]["ApiError"] } };
    };
  };
  createSwapRequest: {
    requestBody: { content: { "application/json": components["schemas"]["CreateSwapProposalRequest"] } };
    responses: {
      201: { content: { "application/json": components["schemas"]["SwapProposalCreatedResponse"] } };
      400: { content: { "application/json": components["schemas"]["ApiError"] } };
      401: { content: { "application/json": components["schemas"]["ApiError"] } };
      404: { content: { "application/json": components["schemas"]["ApiError"] } };
      409: { content: { "application/json": components["schemas"]["ApiError"] } };
      422: { content: { "application/json": components["schemas"]["ValidationError"] } };
    };
  };
  updateSwapStatus: {
    parameters: { path: { swap_id: string } };
    requestBody: { content: { "application/json": components["schemas"]["UpdateSwapStatusRequest"] } };
    responses: {
      200: { content: { "application/json": components["schemas"]["SwapDetailResponse"] } };
      400: { content: { "application/json": components["schemas"]["ApiError"] } };
      401: { content: { "application/json": components["schemas"]["ApiError"] } };
      403: { content: { "application/json": components["schemas"]["ApiError"] } };
      404: { content: { "application/json": components["schemas"]["ApiError"] } };
      409: { content: { "application/json": components["schemas"]["ApiError"] } };
      422: { content: { "application/json": components["schemas"]["ValidationError"] } };
    };
  };
  getSwapQrToken: {
    parameters: { path: { swap_id: string } };
    responses: {
      200: { content: { "application/json": components["schemas"]["QrTokenResponse"] } };
      401: { content: { "application/json": components["schemas"]["ApiError"] } };
      403: { content: { "application/json": components["schemas"]["ApiError"] } };
      409: { content: { "application/json": components["schemas"]["ApiError"] } };
    };
  };
  validateMeetingQr: {
    requestBody: { content: { "application/json": components["schemas"]["ValidateMeetingQrRequest"] } };
    responses: {
      200: { content: { "application/json": components["schemas"]["ValidateMeetingQrResponse"] } };
      400: { content: { "application/json": components["schemas"]["ApiError"] } };
      401: { content: { "application/json": components["schemas"]["ApiError"] } };
      403: { content: { "application/json": components["schemas"]["ApiError"] } };
      409: { content: { "application/json": components["schemas"]["ApiError"] } };
      422: { content: { "application/json": components["schemas"]["ValidationError"] } };
    };
  };
  getSwapMessages: {
    parameters: { path: { swap_id: string }; query?: { limit?: number } };
    responses: {
      200: { content: { "application/json": components["schemas"]["ChatMessageListResponse"] } };
      401: { content: { "application/json": components["schemas"]["ApiError"] } };
      403: { content: { "application/json": components["schemas"]["ApiError"] } };
      404: { content: { "application/json": components["schemas"]["ApiError"] } };
    };
  };
  sendSwapMessage: {
    parameters: { path: { swap_id: string } };
    requestBody: { content: { "application/json": components["schemas"]["SendMessageRequest"] } };
    responses: {
      201: { content: { "application/json": components["schemas"]["ChatMessageResponse"] } };
      400: { content: { "application/json": components["schemas"]["ApiError"] } };
      401: { content: { "application/json": components["schemas"]["ApiError"] } };
      403: { content: { "application/json": components["schemas"]["ApiError"] } };
      422: { content: { "application/json": components["schemas"]["ValidationError"] } };
    };
  };
  submitSwapReview: {
    parameters: { path: { swap_id: string } };
    requestBody: { content: { "application/json": components["schemas"]["SubmitReviewRequest"] } };
    responses: {
      201: { content: { "application/json": components["schemas"]["ReviewSubmissionResponse"] } };
      400: { content: { "application/json": components["schemas"]["ApiError"] } };
      401: { content: { "application/json": components["schemas"]["ApiError"] } };
      403: { content: { "application/json": components["schemas"]["ApiError"] } };
      404: { content: { "application/json": components["schemas"]["ApiError"] } };
      409: { content: { "application/json": components["schemas"]["ApiError"] } };
      422: { content: { "application/json": components["schemas"]["ValidationError"] } };
    };
  };
}
