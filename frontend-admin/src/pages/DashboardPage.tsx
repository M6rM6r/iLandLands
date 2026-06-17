import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '../components/ui/card';
import { Badge } from '../components/ui/badge';
import { Button } from '../components/ui/button';
import { Progress } from '../components/ui/progress';
import {
  LineChart,
  Line,
  BarChart,
  Bar,
  PieChart,
  Pie,
  Cell,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
} from 'recharts';
import {
  Building2,
  MessageSquare,
  DollarSign,
  ArrowUp,
  ArrowDown,
  Download,
  Activity,
  Target,
  Award,
  Users,
} from 'lucide-react';
import { useAuth } from '../hooks/use-auth';
import { useState, useEffect } from 'react';
import api from '../lib/api';
import type { DashboardResponse } from '../lib/types';

// Hardcoded fallback data (shown while loading or on error)
const fallbackMetrics = [
  {
    title: 'Total Listings',
    value: '1,284',
    change: '+12.5%',
    trend: 'up',
    icon: Building2,
    color: 'text-blue-500',
  },
  {
    title: 'Active Inquiries',
    value: '847',
    change: '+8.2%',
    trend: 'up',
    icon: MessageSquare,
    color: 'text-emerald-500',
  },
  {
    title: 'Conversion Rate',
    value: '24.6%',
    change: '-2.1%',
    trend: 'down',
    icon: Target,
    color: 'text-amber-500',
  },
  {
    title: 'Avg Deal Value',
    value: '$2.4M',
    change: '+18.7%',
    trend: 'up',
    icon: DollarSign,
    color: 'text-purple-500',
  },
];

const dailyInquiries = [
  { date: 'Jun 1', inquiries: 45 },
  { date: 'Jun 5', inquiries: 52 },
  { date: 'Jun 10', inquiries: 38 },
  { date: 'Jun 15', inquiries: 65 },
  { date: 'Jun 17', inquiries: 72 },
];

const listingsByCountry = [
  { country: 'UAE', count: 420, percentage: 32.7 },
  { country: 'Saudi Arabia', count: 380, percentage: 29.6 },
  { country: 'Qatar', count: 215, percentage: 16.7 },
  { country: 'Kuwait', count: 145, percentage: 11.3 },
  { country: 'Bahrain', count: 75, percentage: 5.8 },
  { country: 'Oman', count: 49, percentage: 3.9 },
];

const leadSources = [
  { name: 'Website', value: 45, color: '#3B82F6' },
  { name: 'WhatsApp', value: 28, color: '#25D366' },
  { name: 'Referral', value: 15, color: '#C9A227' },
  { name: 'Social', value: 8, color: '#EC4899' },
  { name: 'Direct', value: 4, color: '#8B5CF6' },
];

const funnelData = [
  { stage: 'View', count: 12450, percentage: 100 },
  { stage: 'Inquiry', count: 3280, percentage: 26.3 },
  { stage: 'Visit', count: 847, percentage: 6.8 },
  { stage: 'Deal', count: 208, percentage: 1.7 },
];

const recentActivity = [
  { id: 1, type: 'listing', action: 'New listing approved', title: 'Luxury Villa in Dubai Marina', time: '5 min ago' },
  { id: 2, type: 'inquiry', action: 'New inquiry received', title: 'Penthouse in Riyadh - $3.2M', time: '12 min ago' },
  { id: 3, type: 'deal', action: 'Deal closed', title: 'Commercial Land in Doha - $8.5M', time: '1 hour ago' },
  { id: 4, type: 'user', action: 'New agent registered', title: 'Ahmed Al-Rashid', time: '2 hours ago' },
  { id: 5, type: 'listing', action: 'Listing featured', title: 'Waterfront Estate in Bahrain', time: '3 hours ago' },
];

export default function DashboardPage() {
  const { user } = useAuth();
  const [metrics, setMetrics] = useState(fallbackMetrics);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    api.get<DashboardResponse>('/dashboard/metrics')
      .then((data) => {
        const m = data.metrics;
        setMetrics([
          { title: 'Total Listings', value: m.totalListings.toLocaleString(), change: '+12.5%', trend: 'up' as const, icon: Building2, color: 'text-blue-500' },
          { title: 'Active Inquiries', value: m.activeInquiries.toLocaleString(), change: '+8.2%', trend: 'up' as const, icon: MessageSquare, color: 'text-emerald-500' },
          { title: 'Conversion Rate', value: `${m.conversionRate}%`, change: '-2.1%', trend: 'down' as const, icon: Target, color: 'text-amber-500' },
          { title: 'Avg Deal Value', value: `$${(m.avgDealValue / 1_000_000).toFixed(1)}M`, change: '+18.7%', trend: 'up' as const, icon: DollarSign, color: 'text-purple-500' },
        ]);
        setLoading(false);
      })
      .catch(() => {
        setLoading(false);
      });
  }, []);

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold text-foreground">Dashboard</h1>
          <p className="text-muted-foreground">Welcome back, {user?.first_name || user?.email}</p>
        </div>
        <Button variant="outline" className="gap-2">
          <Download className="h-4 w-4" />
          Export Report
        </Button>
      </div>

      <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
        {metrics.map((metric) => (
          <Card key={metric.title}>
            <CardContent className="pt-6">
              <div className="flex items-center justify-between">
                <div className={`rounded-lg p-2 ${metric.color} bg-opacity-10`}>
                  <metric.icon className={`h-5 w-5 ${metric.color}`} />
                </div>
                <Badge variant={metric.trend === 'up' ? 'default' : 'destructive'} className="gap-1">
                  {metric.trend === 'up' ? (
                    <ArrowUp className="h-3 w-3" />
                  ) : (
                    <ArrowDown className="h-3 w-3" />
                  )}
                  {metric.change}
                </Badge>
              </div>
              <div className="mt-4">
                <p className="text-2xl font-bold">{metric.value}</p>
                <p className="text-sm text-muted-foreground">{metric.title}</p>
              </div>
            </CardContent>
          </Card>
        ))}
      </div>

      <div className="grid gap-4 lg:grid-cols-2">
        <Card>
          <CardHeader>
            <CardTitle>Daily Inquiries</CardTitle>
            <CardDescription>Last 30 days inquiry trend</CardDescription>
          </CardHeader>
          <CardContent>
            <div className="h-[300px]">
              <ResponsiveContainer width="100%" height="100%">
                <LineChart data={dailyInquiries}>
                  <CartesianGrid strokeDasharray="3 3" className="stroke-muted" />
                  <XAxis dataKey="date" className="text-xs" />
                  <YAxis className="text-xs" />
                  <Tooltip
                    contentStyle={{
                      backgroundColor: 'hsl(var(--card))',
                      border: '1px solid hsl(var(--border))',
                      borderRadius: '8px',
                    }}
                  />
                  <Line
                    type="monotone"
                    dataKey="inquiries"
                    stroke="#C9A227"
                    strokeWidth={2}
                    dot={{ fill: '#C9A227', strokeWidth: 2 }}
                  />
                </LineChart>
              </ResponsiveContainer>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle>Listings by Country</CardTitle>
            <CardDescription>Distribution across GCC countries</CardDescription>
          </CardHeader>
          <CardContent>
            <div className="h-[300px]">
              <ResponsiveContainer width="100%" height="100%">
                <BarChart data={listingsByCountry} layout="vertical">
                  <CartesianGrid strokeDasharray="3 3" className="stroke-muted" />
                  <XAxis type="number" className="text-xs" />
                  <YAxis dataKey="country" type="category" className="text-xs" width={80} />
                  <Tooltip
                    contentStyle={{
                      backgroundColor: 'hsl(var(--card))',
                      border: '1px solid hsl(var(--border))',
                      borderRadius: '8px',
                    }}
                  />
                  <Bar dataKey="count" fill="#0A2540" radius={[0, 4, 4, 0]} />
                </BarChart>
              </ResponsiveContainer>
            </div>
          </CardContent>
        </Card>
      </div>

      <div className="grid gap-4 lg:grid-cols-3">
        <Card>
          <CardHeader>
            <CardTitle>Lead Sources</CardTitle>
            <CardDescription>Where your leads are coming from</CardDescription>
          </CardHeader>
          <CardContent>
            <div className="h-[250px]">
              <ResponsiveContainer width="100%" height="100%">
                <PieChart>
                  <Pie
                    data={leadSources}
                    cx="50%"
                    cy="50%"
                    innerRadius={60}
                    outerRadius={100}
                    paddingAngle={2}
                    dataKey="value"
                  >
                    {leadSources.map((entry, index) => (
                      <Cell key={`cell-${index}`} fill={entry.color} />
                    ))}
                  </Pie>
                  <Tooltip />
                </PieChart>
              </ResponsiveContainer>
            </div>
            <div className="mt-4 space-y-2">
              {leadSources.map((source) => (
                <div key={source.name} className="flex items-center justify-between">
                  <div className="flex items-center gap-2">
                    <div
                      className="h-3 w-3 rounded-full"
                      style={{ backgroundColor: source.color }}
                    />
                    <span className="text-sm">{source.name}</span>
                  </div>
                  <span className="text-sm font-medium">{source.value}%</span>
                </div>
              ))}
            </div>
          </CardContent>
        </Card>

        <Card className="lg:col-span-2">
          <CardHeader>
            <CardTitle>Sales Funnel</CardTitle>
            <CardDescription>Conversion pipeline visualization</CardDescription>
          </CardHeader>
          <CardContent>
            <div className="space-y-4">
              {funnelData.map((stage, index) => (
                <div key={stage.stage}>
                  <div className="flex items-center justify-between mb-2">
                    <div className="flex items-center gap-2">
                      <span className="text-sm font-medium">{stage.stage}</span>
                      <Badge variant="secondary">{stage.count.toLocaleString()}</Badge>
                    </div>
                    <span className="text-sm text-muted-foreground">
                      {stage.percentage.toFixed(1)}%
                    </span>
                  </div>
                  <Progress
                    value={stage.percentage}
                    className="h-3"
                    style={{
                      backgroundColor: 'hsl(var(--muted))',
                    }}
                  />
                  {index < funnelData.length - 1 && (
                    <div className="flex justify-center my-1">
                      <ArrowDown className="h-4 w-4 text-muted-foreground" />
                    </div>
                  )}
                </div>
              ))}
            </div>
          </CardContent>
        </Card>
      </div>

      <Card>
        <CardHeader>
          <CardTitle>Recent Activity</CardTitle>
          <CardDescription>Latest events in the system</CardDescription>
        </CardHeader>
        <CardContent>
          <div className="space-y-4">
            {recentActivity.map((activity) => (
              <div
                key={activity.id}
                className="flex items-start gap-4 pb-4 border-b border-border last:border-0"
              >
                <div className="mt-1">
                  {activity.type === 'listing' && (
                    <Activity className="h-4 w-4 text-blue-500" />
                  )}
                  {activity.type === 'inquiry' && (
                    <MessageSquare className="h-4 w-4 text-emerald-500" />
                  )}
                  {activity.type === 'deal' && (
                    <Award className="h-4 w-4 text-amber-500" />
                  )}
                  {activity.type === 'user' && (
                    <Users className="h-4 w-4 text-purple-500" />
                  )}
                </div>
                <div className="flex-1 min-w-0">
                  <p className="text-sm font-medium">{activity.action}</p>
                  <p className="text-sm text-muted-foreground truncate">
                    {activity.title}
                  </p>
                </div>
                <span className="text-xs text-muted-foreground whitespace-nowrap">
                  {activity.time}
                </span>
              </div>
            ))}
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
