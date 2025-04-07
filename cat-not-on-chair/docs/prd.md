# Pomodoro Timer PRD

## Introduction

This iOS app will help user to have more protuctive work session by allowing users to start focus time with other apps blocked.

## User Stories

- **US1:** *As a user, I want to start a focus session that all my other apps are blocked*

- **US2:** *As a user, I want to spend couple hours for deep work session, so I will have multiple focus time and break time*

- **US3:** *As a user, I want to be able to see all my past focus session and see the progress I made*

## Acceptance Criteria

**For US1:**

- User need to start a focus session by clicking the start button on the screen. 
- There should be three ways of blocking. Strict mode would not allow users to use any other apps during the focus time. Whitelist mode would allow users to choose which apps they want to use during focus time. Relax allow users to use any apps during focus time. 
- User should be able to close the app during the focus time, and the timer should continue goes down. In the future version, user should be able to see the count down from the live activity. 

**For US2:**

- User should be able to adjust how long they want the focus and break time to be. For future version, users should be able to choose how many short break they want before having a long break.
- If user stops the session during the focus time, it counts as a failed session, if the user stops the session during the break time, it still counts as a successful session. 

**For US3:**

- User can see from a screen the statics from past week and month. They should be able to see how many focus sessions they had and how many focus sessions they failed. 

**For all users**
- This app would be cat themed, we will have a chair showing when the app starts and when the focus time starts, we will show a cat sitting on the chair. 

## Technical Note
- We should utilize the screen time or family control framework on iOS to block apps. 
- In the future version, we should use live activity framework to display the count down when the focus time is on. 
- No need to use SwiftUI, just the normal UIKit would be fine. 
