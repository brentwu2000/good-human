# Combat Camera System v0.1
Presentation contexts only: EXPLORE / COMBAT_TENSION / COMBAT_ACTIVE / COMBAT_CRISIS / COMBAT_RELEASE.

Two anchors:
FollowAnchor = PlayerDog
FocusAnchor = PlayerHuman

Blend position/distance/focus continuously. Combat Snap is interpolation, not a cut.
Use soft owner focus and optional opponent composition. Dog rotation is independent of camera facing.
Release holds the resolution beat briefly, then blends to Explore.

Debug: context, focus weight, desired/current distance, owner screen position, angular velocity, occlusion.
