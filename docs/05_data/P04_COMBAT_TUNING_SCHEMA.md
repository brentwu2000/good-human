# P-04 Combat Tuning Schema
Keep data-driven.

AttackData:
id, ideal_range, windup_seconds, strike_seconds, contact_start, contact_end, follow_through_seconds, recovery_seconds, damage, hit_stop_seconds, displacement, tags.

SpacingData:
ideal_min, ideal_max, hard_min_separation, approach_speed, circle_speed, backstep_distance.

PresenceData:
body_shape refs, slide response, fast_dog_contact_threshold, minor_balance_response.

Do not hard-code final balance values into combat logic.
