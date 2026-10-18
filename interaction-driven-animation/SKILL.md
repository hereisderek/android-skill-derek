---
name: interaction-driven-animation
description: Make animations that a user triggers by touching, dragging, scrolling or swiping follow the input exactly, and only continue on their own with momentum when the input stops. Use when building or reviewing collapsing headers, carousels, bottom sheets, pull to refresh, swipe actions, or any motion that starts from a gesture, on any platform (Compose, SwiftUI, web).
---

# Interaction-driven animation

Apply this when building or reviewing any animation that starts from a user gesture: scroll, drag, swipe, pinch, pull to refresh, collapsing headers, carousels, bottom sheets, and similar.

## Rule

1. While the user's input is active, the animated state is a direct function of the input (finger position, scroll offset, drag distance). It tracks the input one to one. Do not play a separate timed animation, a fixed-duration transition, or a switch triggered by crossing a threshold during the gesture.
2. When the input ends or is interrupted (finger lifted, gesture cancelled, scroll stopped), finish the rest of the motion from the input's momentum and velocity so it feels natural. Use a fling or spring that starts from the release velocity and the current position. A timed tween that ignores them is not enough.
3. If the user touches again while the motion is still settling, stop the settling animation at once and hand control back to the input from the current position, with no jump.

## Checks

- Drag slowly: the element moves exactly as far as the finger, at the same speed.
- Drag back and forth: the element stays in step, with no lag, snap or replay.
- Release fast, and release while still: the motion carries on from the same velocity and position, then comes to rest. It does not restart from the beginning.
- No one-shot animation fires when a scroll offset crosses a threshold. Map the offset to a continuous value instead (for example a 0to 1 progress) and drive size, opacity or position from it.

## Exception

An explicit instruction from the user for a particular animation takes precedence over this rule.
