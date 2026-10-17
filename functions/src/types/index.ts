import { Request } from 'express';

export type SwapStatus = 'PENDING' | 'MATCHED' | 'SCHEDULED' | 'COMPLETED' | 'CANCELLED' | 'REJECTED';
export type SkillType = 'OFFERED' | 'DESIRED';
export type ProficiencyLevel = 'BEGINNER' | 'INTERMEDIATE' | 'ADVANCED' | 'EXPERT';
export type MessageType = 'TEXT' | 'QUICK_REPLY' | 'ACTION_WIDGET';
export type AvailabilityStatus = 'AVAILABLE' | 'UNAVAILABLE';

export interface AuthenticatedUser {
  userId: string;
  displayName: string;
  email?: string;
  provider: 'GOOGLE' | 'APPLE';
}

export interface AuthenticatedRequest extends Request {
  user?: AuthenticatedUser;
}

export interface SkillItem {
  skill_id: string;
  name: string;
  category: string;
  proficiency_level?: ProficiencyLevel;
}

export interface PublicProfileResponse {
  user_id: string;
  basic_info: {
    display_name: string;
    avatar_url: string | null;
    bio: string | null;
  };
  location: {
    zone_name: string;
    distance_km: number | null;
  };
  reputation: {
    average_score: number;
    total_reviews: number;
    punctuality_score: number;
  };
  skills: {
    offered: SkillItem[];
    desired: SkillItem[];
  };
  availability_status: AvailabilityStatus;
  metadata: {
    joined_at: string;
  };
}

export interface ReviewItem {
  review_id: string;
  swap_id: string;
  reviewer: {
    user_id: string;
    display_name: string;
    avatar_url: string | null;
  };
  rating: number;
  comment: string;
  skill_confirmed: boolean;
  created_at: string;
}

export interface PaginatedResponse<T> {
  data: T[];
  pagination: {
    page: number;
    limit: number;
    total: number;
    total_pages: number;
  };
}

export interface SwapDetail {
  swap_id: string;
  requester_id: string;
  receiver_id: string;
  offered_skill_id: string;
  requested_skill_id: string;
  status: SwapStatus;
  scheduled_at: string | null;
  completed_at: string | null;
  meeting_location: string | null;
  cancellation_reason?: string | null;
  qr_secret?: string | null;
  created_at: string;
  updated_at: string;
}

export interface ChatMessage {
  message_id: string;
  swap_id: string;
  sender_id: string;
  message_type: MessageType;
  content: string;
  widget_payload?: Record<string, any> | null;
  is_system: boolean;
  created_at: string;
}

export interface AppErrorOptions {
  code: string;
  message: string;
  statusCode: number;
  details?: any;
}

export class AppError extends Error {
  public readonly code: string;
  public readonly statusCode: number;
  public readonly details?: any;

  constructor(options: AppErrorOptions) {
    super(options.message);
    this.code = options.code;
    this.statusCode = options.statusCode;
    this.details = options.details;
    Object.setPrototypeOf(this, new.target.prototype);
  }
}
