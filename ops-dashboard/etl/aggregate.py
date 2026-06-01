import json
import pandas as pd
from datetime import datetime, timedelta
from collections import defaultdict

def load_events(file_path):
    with open(file_path, 'r') as f:
        return json.load(f)

def aggregate_dau(events):
    daily_users = defaultdict(set)
    for event in events:
        date = datetime.fromisoformat(event['timestamp'].replace('Z', '+00:00')).date()
        daily_users[date].add(event['user_id'])
    
    dau = []
    for date in sorted(daily_users.keys()):
        dau.append({'date': str(date), 'value': len(daily_users[date])})
    return dau

def aggregate_session_length(events):
    daily_sessions = defaultdict(list)
    for event in events:
        if event['event_type'] == 'session_start':
            date = datetime.fromisoformat(event['timestamp'].replace('Z', '+00:00')).date()
            daily_sessions[date].append(event['session_length'])
    
    session_length = []
    for date in sorted(daily_sessions.keys()):
        avg_length = sum(daily_sessions[date]) / len(daily_sessions[date]) if daily_sessions[date] else 0
        session_length.append({'date': str(date), 'value': round(avg_length, 1)})
    return session_length

def aggregate_favorite_conversion(events):
    daily_favorites = defaultdict(int)
    daily_sessions = defaultdict(int)
    for event in events:
        date = datetime.fromisoformat(event['timestamp'].replace('Z', '+00:00')).date()
        if event['event_type'] == 'session_start':
            daily_sessions[date] += 1
        elif event['event_type'] == 'favorite':
            daily_favorites[date] += 1
    
    favorite_conversion = []
    for date in sorted(set(daily_sessions.keys()) | set(daily_favorites.keys())):
        sessions = daily_sessions.get(date, 0)
        favorites = daily_favorites.get(date, 0)
        rate = (favorites / sessions * 100) if sessions > 0 else 0
        favorite_conversion.append({'date': str(date), 'value': round(rate, 1)})
    return favorite_conversion

def aggregate_listing_engagement(events):
    daily_views = defaultdict(int)
    for event in events:
        if event['event_type'] == 'view_listing':
            date = datetime.fromisoformat(event['timestamp'].replace('Z', '+00:00')).date()
            daily_views[date] += 1
    
    listing_engagement = []
    for date in sorted(daily_views.keys()):
        listing_engagement.append({'date': str(date), 'value': daily_views[date]})
    return listing_engagement

def aggregate_retention_proxies(events):
    # Simple proxy: users with multiple sessions in a week
    user_sessions = defaultdict(list)
    for event in events:
        if event['event_type'] == 'session_start':
            date = datetime.fromisoformat(event['timestamp'].replace('Z', '+00:00')).date()
            user_sessions[event['user_id']].append(date)
    
    weekly_retention = defaultdict(int)
    for user, dates in user_sessions.items():
        dates.sort()
        for i in range(len(dates) - 1):
            if (dates[i+1] - dates[i]).days <= 7:
                week = dates[i].isocalendar()[1]
                weekly_retention[week] += 1
                break
    
    retention_proxies = []
    for week in sorted(weekly_retention.keys()):
        retention_proxies.append({'date': f'Week {week}', 'value': weekly_retention[week]})
    return retention_proxies

def main():
    events = load_events('../data/sample_events.json')
    
    aggregated = {
        'dau': aggregate_dau(events),
        'session_length': aggregate_session_length(events),
        'favorite_conversion': aggregate_favorite_conversion(events),
        'listing_engagement': aggregate_listing_engagement(events),
        'retention_proxies': aggregate_retention_proxies(events)
    }
    
    with open('../data/sample_aggregated.json', 'w') as f:
        json.dump(aggregated, f, indent=2)

if __name__ == '__main__':
    main()