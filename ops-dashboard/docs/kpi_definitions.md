# KPI Definitions

## Daily Active Users (DAU)
- **Definition**: The number of unique users who logged at least one session on a given day.
- **Calculation**: Count distinct user_ids from session_start events per day.
- **Purpose**: Measures daily user engagement and platform activity.

## Session Length
- **Definition**: The average duration of user sessions in minutes.
- **Calculation**: Average of session_length from session_start events per day.
- **Purpose**: Indicates how long users spend on the platform, reflecting engagement quality.

## Favorite Conversion
- **Definition**: The percentage of sessions that result in a favorite action.
- **Calculation**: (Number of favorite events / Number of session_start events) * 100 per day.
- **Purpose**: Measures conversion from browsing to saving listings.

## Listing Engagement
- **Definition**: The total number of listing view events per day.
- **Calculation**: Count of view_listing events per day.
- **Purpose**: Tracks how often users interact with property listings.

## Retention Proxies
- **Definition**: A proxy metric for user retention, counting users who return within a week.
- **Calculation**: Number of users with at least two sessions within 7 days in a given week.
- **Purpose**: Estimates user retention and loyalty to the platform.