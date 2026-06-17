import { useState, useRef } from 'react';
import { Card, CardContent } from '../components/ui/card';
import { Badge } from '../components/ui/badge';
import { Button } from '../components/ui/button';
import { Input } from '../components/ui/input';
import { Avatar, AvatarFallback } from '../components/ui/avatar';
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
} from '../components/ui/dialog';
import {
  MessageCircle,
  Phone,
  Mail,
  GripVertical,
  Search,
} from 'lucide-react';
import { toast } from 'sonner';
import type { Inquiry, InquiryStatus } from '../lib/types';

type KanbanColumn = {
  id: InquiryStatus;
  title: string;
  color: string;
};

const columns: KanbanColumn[] = [
  { id: 'new', title: 'New', color: 'bg-slate-500' },
  { id: 'contacted', title: 'Contacted', color: 'bg-blue-500' },
  { id: 'scheduled', title: 'Scheduled', color: 'bg-amber-500' },
  { id: 'visited', title: 'Visited', color: 'bg-purple-500' },
  { id: 'negotiating', title: 'Negotiating', color: 'bg-orange-500' },
  { id: 'closed_won', title: 'Closed Won', color: 'bg-emerald-500' },
  { id: 'closed_lost', title: 'Closed Lost', color: 'bg-red-500' },
];

const mockInquiries: Inquiry[] = [
  {
    id: '1',
    listingId: 'L1',
    listingTitle: 'Luxury Villa in Palm Jumeirah',
    clientName: 'John Smith',
    clientEmail: 'john.smith@email.com',
    clientPhone: '+971501234567',
    message: 'Interested in viewing this property. Available this weekend.',
    status: 'new',
    leadScore: 85,
    source: 'website',
    agentId: 'A1',
    agentName: 'Ahmed Hassan',
    createdAt: '2024-06-17T10:30:00Z',
    updatedAt: '2024-06-17T10:30:00Z',
    hubspotSynced: true,
  },
  {
    id: '2',
    listingId: 'L2',
    listingTitle: 'Modern Penthouse in Riyadh',
    clientName: 'Sarah Al-Farsi',
    clientEmail: 'sarah.alfarsi@email.com',
    clientPhone: '+966501234567',
    message: 'Looking for a penthouse with city views. Need 3+ bedrooms.',
    status: 'contacted',
    leadScore: 72,
    source: 'whatsapp',
    agentId: 'A2',
    agentName: 'Fatima Al-Rashid',
    createdAt: '2024-06-16T14:00:00Z',
    updatedAt: '2024-06-17T09:00:00Z',
    hubspotSynced: true,
  },
  {
    id: '3',
    listingId: 'L3',
    listingTitle: 'Waterfront Estate in Doha',
    clientName: 'Mohammed Khan',
    clientEmail: 'mkhan@email.com',
    clientPhone: '+97450123456',
    message: 'Budget is $15-20M. Need a property with marina access.',
    status: 'scheduled',
    leadScore: 91,
    source: 'referral',
    agentId: 'A1',
    agentName: 'Ahmed Hassan',
    createdAt: '2024-06-15T11:00:00Z',
    updatedAt: '2024-06-17T08:30:00Z',
    hubspotSynced: true,
    scheduledVisit: '2024-06-20T15:00:00Z',
  },
  {
    id: '4',
    listingId: 'L4',
    listingTitle: 'Commercial Land in Bahrain',
    clientName: 'Ahmed Al-Rashid',
    clientEmail: 'ahmed.rashid@company.com',
    clientPhone: '+97339123456',
    message: 'Looking for commercial land for new development project.',
    status: 'visited',
    leadScore: 68,
    source: 'direct',
    agentId: 'A3',
    agentName: 'Mohammed Khalil',
    createdAt: '2024-06-14T09:00:00Z',
    updatedAt: '2024-06-16T17:00:00Z',
    hubspotSynced: false,
  },
  {
    id: '5',
    listingId: 'L5',
    listingTitle: 'Luxury Apartment in Kuwait',
    clientName: 'Fatima Nasser',
    clientEmail: 'fatima.n@email.com',
    clientPhone: '+96599123456',
    message: 'Need a 2-bedroom apartment with modern amenities.',
    status: 'negotiating',
    leadScore: 78,
    source: 'social',
    agentId: 'A2',
    agentName: 'Fatima Al-Rashid',
    createdAt: '2024-06-13T16:00:00Z',
    updatedAt: '2024-06-17T11:00:00Z',
    hubspotSynced: true,
  },
  {
    id: '6',
    listingId: 'L1',
    listingTitle: 'Luxury Villa in Palm Jumeirah',
    clientName: 'Robert Chen',
    clientEmail: 'r.chen@email.com',
    clientPhone: '+97155123456',
    message: 'Interested in long-term investment in Dubai real estate.',
    status: 'closed_won',
    leadScore: 95,
    source: 'website',
    agentId: 'A1',
    agentName: 'Ahmed Hassan',
    createdAt: '2024-06-10T10:00:00Z',
    updatedAt: '2024-06-15T14:00:00Z',
    hubspotSynced: true,
  },
  {
    id: '7',
    listingId: 'L2',
    listingTitle: 'Modern Penthouse in Riyadh',
    clientName: 'Lisa Wong',
    clientEmail: 'lisa.wong@email.com',
    clientPhone: '+96655123456',
    message: 'Looking for investment property under $5M.',
    status: 'closed_lost',
    leadScore: 45,
    source: 'website',
    agentId: 'A2',
    agentName: 'Fatima Al-Rashid',
    createdAt: '2024-06-08T12:00:00Z',
    updatedAt: '2024-06-12T16:00:00Z',
    hubspotSynced: true,
  },
];

const leadScoreColors = (score: number) => {
  if (score >= 80) return 'bg-emerald-500';
  if (score >= 60) return 'bg-amber-500';
  if (score >= 40) return 'bg-orange-500';
  return 'bg-red-500';
};

const sourceIcons: Record<string, string> = {
  website: 'bg-blue-500',
  whatsapp: 'bg-green-500',
  referral: 'bg-amber-500',
  social: 'bg-pink-500',
  direct: 'bg-purple-500',
};

export default function InquiriesPage() {
  const [inquiries, setInquiries] = useState<Inquiry[]>(mockInquiries);
  const [selectedInquiry, setSelectedInquiry] = useState<Inquiry | null>(null);
  const [isDetailOpen, setIsDetailOpen] = useState(false);
  const [searchQuery, setSearchQuery] = useState('');
  const [draggedId, setDraggedId] = useState<string | null>(null);
  const dragOverColumn = useRef<InquiryStatus | null>(null);

  const getInquiriesByStatus = (status: InquiryStatus) =>
    inquiries.filter(
      (inq) =>
        inq.status === status &&
        (inq.clientName.toLowerCase().includes(searchQuery.toLowerCase()) ||
          inq.listingTitle.toLowerCase().includes(searchQuery.toLowerCase()))
    );

  const handleDragStart = (e: React.DragEvent, inquiryId: string) => {
    setDraggedId(inquiryId);
    e.dataTransfer.effectAllowed = 'move';
  };

  const handleDragOver = (e: React.DragEvent, columnId: InquiryStatus) => {
    e.preventDefault();
    dragOverColumn.current = columnId;
  };

  const handleDrop = (e: React.DragEvent, newStatus: InquiryStatus) => {
    e.preventDefault();
    if (draggedId) {
      setInquiries((prev) =>
        prev.map((inq) =>
          inq.id === draggedId ? { ...inq, status: newStatus, updatedAt: new Date().toISOString() } : inq
        )
      );
      toast.success(`Inquiry moved to ${columns.find((c) => c.id === newStatus)?.title}`);
      setDraggedId(null);
    }
  };

  const handleWhatsApp = (phone: string) => {
    const formattedPhone = phone.replace(/\D/g, '');
    window.open(`https://wa.me/${formattedPhone}`, '_blank');
  };

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold">Inquiries Pipeline</h1>
          <p className="text-muted-foreground">Track and manage client inquiries</p>
        </div>
        <div className="flex items-center gap-4">
          <div className="relative w-64">
            <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
            <Input
              placeholder="Search inquiries..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="pl-10"
            />
          </div>
        </div>
      </div>

      <div className="flex gap-4 overflow-x-auto pb-4">
        {columns.map((column) => {
          const columnInquiries = getInquiriesByStatus(column.id);
          return (
            <div
              key={column.id}
              className="flex w-72 shrink-0 flex-col"
              onDragOver={(e) => handleDragOver(e, column.id)}
              onDrop={(e) => handleDrop(e, column.id)}
            >
              <div className="mb-3 flex items-center justify-between rounded-lg bg-card p-3">
                <div className="flex items-center gap-2">
                  <div className={`h-3 w-3 rounded-full ${column.color}`} />
                  <span className="font-medium">{column.title}</span>
                </div>
                <Badge variant="secondary">{columnInquiries.length}</Badge>
              </div>
              <div className="flex-1 space-y-3 rounded-lg bg-muted/30 p-2 min-h-[200px]">
                {columnInquiries.length === 0 ? (
                  <div className="flex h-32 items-center justify-center text-sm text-muted-foreground">
                    No inquiries
                  </div>
                ) : (
                  columnInquiries.map((inquiry) => (
                    <Card
                      key={inquiry.id}
                      className="cursor-grab active:cursor-grabbing hover:shadow-md transition-shadow"
                      draggable
                      onDragStart={(e) => handleDragStart(e, inquiry.id)}
                      onClick={() => {
                        setSelectedInquiry(inquiry);
                        setIsDetailOpen(true);
                      }}
                    >
                      <CardContent className="p-3 space-y-2">
                        <div className="flex items-start justify-between">
                          <GripVertical className="h-4 w-4 text-muted-foreground opacity-50" />
                          <div
                            className={`flex h-6 w-6 items-center justify-center rounded-full text-xs font-bold text-white ${leadScoreColors(inquiry.leadScore)}`}
                          >
                            {inquiry.leadScore}
                          </div>
                        </div>
                        <div>
                          <p className="font-medium text-sm line-clamp-1">{inquiry.clientName}</p>
                          <p className="text-xs text-muted-foreground line-clamp-2">{inquiry.listingTitle}</p>
                        </div>
                        <div className="flex items-center gap-2 text-xs text-muted-foreground">
                          <div className={`h-2 w-2 rounded-full ${sourceIcons[inquiry.source]}`} />
                          <span className="capitalize">{inquiry.source}</span>
                          {inquiry.hubspotSynced && (
                            <Badge variant="outline" className="text-xs">
                              HubSpot
                            </Badge>
                          )}
                        </div>
                      </CardContent>
                    </Card>
                  ))
                )}
              </div>
            </div>
          );
        })}
      </div>

      <Dialog open={isDetailOpen} onOpenChange={setIsDetailOpen}>
        <DialogContent className="max-w-lg">
          <DialogHeader>
            <DialogTitle>Inquiry Details</DialogTitle>
            <DialogDescription>
              View and manage inquiry information
            </DialogDescription>
          </DialogHeader>
          {selectedInquiry && (
            <div className="space-y-4">
              <div className="rounded-lg bg-muted p-4">
                <div className="flex items-center gap-3 mb-4">
                  <Avatar className="h-12 w-12">
                    <AvatarFallback className="bg-primary text-primary-foreground">
                      {selectedInquiry.clientName
                        .split(' ')
                        .map((n) => n[0])
                        .join('')}
                    </AvatarFallback>
                  </Avatar>
                  <div>
                    <p className="font-medium">{selectedInquiry.clientName}</p>
                    <div className="flex items-center gap-2">
                      <Badge variant="outline" className="capitalize">
                        {selectedInquiry.status.replace('_', ' ')}
                      </Badge>
                      <div
                        className={`flex h-5 w-5 items-center justify-center rounded-full text-xs font-bold text-white ${leadScoreColors(selectedInquiry.leadScore)}`}
                      >
                        {selectedInquiry.leadScore}
                      </div>
                    </div>
                  </div>
                </div>
                <div className="grid gap-2 text-sm">
                  <div className="flex items-center gap-2">
                    <Mail className="h-4 w-4 text-muted-foreground" />
                    <a href={`mailto:${selectedInquiry.clientEmail}`} className="text-primary hover:underline">
                      {selectedInquiry.clientEmail}
                    </a>
                  </div>
                  <div className="flex items-center gap-2">
                    <Phone className="h-4 w-4 text-muted-foreground" />
                    <span>{selectedInquiry.clientPhone}</span>
                  </div>
                </div>
              </div>

              <div>
                <h4 className="font-medium mb-2">Listing</h4>
                <p className="text-sm text-muted-foreground">{selectedInquiry.listingTitle}</p>
              </div>

              <div>
                <h4 className="font-medium mb-2">Message</h4>
                <p className="text-sm text-muted-foreground">{selectedInquiry.message}</p>
              </div>

              <div className="grid grid-cols-2 gap-4 text-sm">
                <div>
                  <h4 className="font-medium mb-1">Source</h4>
                  <Badge variant="secondary" className="capitalize">
                    {selectedInquiry.source}
                  </Badge>
                </div>
                <div>
                  <h4 className="font-medium mb-1">Agent</h4>
                  <p className="text-muted-foreground">{selectedInquiry.agentName}</p>
                </div>
                <div>
                  <h4 className="font-medium mb-1">Created</h4>
                  <p className="text-muted-foreground">
                    {new Date(selectedInquiry.createdAt).toLocaleDateString()}
                  </p>
                </div>
                <div>
                  <h4 className="font-medium mb-1">HubSpot Sync</h4>
                  <Badge variant={selectedInquiry.hubspotSynced ? 'default' : 'secondary'}>
                    {selectedInquiry.hubspotSynced ? 'Synced' : 'Pending'}
                  </Badge>
                </div>
              </div>

              <div className="flex gap-2 pt-4">
                <Button
                  className="flex-1 bg-green-600 hover:bg-green-700"
                  onClick={() => handleWhatsApp(selectedInquiry.clientPhone)}
                >
                  <MessageCircle className="mr-2 h-4 w-4" />
                  WhatsApp
                </Button>
                <Button variant="outline" className="flex-1">
                  <Phone className="mr-2 h-4 w-4" />
                  Call
                </Button>
                <Button variant="outline" className="flex-1">
                  <Mail className="mr-2 h-4 w-4" />
                  Email
                </Button>
              </div>
            </div>
          )}
        </DialogContent>
      </Dialog>
    </div>
  );
}
