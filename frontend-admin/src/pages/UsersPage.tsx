import { useState } from 'react';
import { ColumnDef, flexRender, getCoreRowModel, useReactTable, getPaginationRowModel, getSortedRowModel, SortingState } from '@tanstack/react-table';
import { ArrowUpDown, MoreHorizontal, Plus, Pencil, Trash2, Star, Shield, Activity, TrendingUp } from 'lucide-react';
import { Button } from '../components/ui/button';
import { Input } from '../components/ui/input';
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '../components/ui/table';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '../components/ui/card';
import { Badge } from '../components/ui/badge';
import { Avatar, AvatarFallback, AvatarImage } from '../components/ui/avatar';
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from '../components/ui/dialog';
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuLabel,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from '../components/ui/dropdown-menu';
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '../components/ui/select';
import { Label } from '../components/ui/label';
import { toast } from 'sonner';
import type { Agent, SubscriptionTier } from '../lib/types';

const mockAgents: Agent[] = [
  {
    id: '1',
    userId: 'U1',
    name: 'Ahmed Hassan',
    email: 'ahmed@gulflands.com',
    phone: '+97150123456',
    subscriptionTier: 'enterprise',
    listingsCount: 45,
    dealsClosed: 12,
    avgResponseTime: 1.2,
    rating: 4.9,
    createdAt: '2023-01-15',
    active: true,
  },
  {
    id: '2',
    userId: 'U2',
    name: 'Fatima Al-Rashid',
    email: 'fatima@gulflands.com',
    phone: '+96650123456',
    subscriptionTier: 'pro',
    listingsCount: 32,
    dealsClosed: 8,
    avgResponseTime: 2.1,
    rating: 4.7,
    createdAt: '2023-03-20',
    active: true,
  },
  {
    id: '3',
    userId: 'U3',
    name: 'Mohammed Khalil',
    email: 'mohammed@gulflands.com',
    phone: '+97339123456',
    subscriptionTier: 'pro',
    listingsCount: 28,
    dealsClosed: 5,
    avgResponseTime: 3.5,
    rating: 4.5,
    createdAt: '2023-05-10',
    active: true,
  },
  {
    id: '4',
    userId: 'U4',
    name: 'Sarah Williams',
    email: 'sarah@gulflands.com',
    phone: '+97450123456',
    subscriptionTier: 'free',
    listingsCount: 12,
    dealsClosed: 2,
    avgResponseTime: 5.2,
    rating: 4.2,
    createdAt: '2023-08-25',
    active: true,
  },
  {
    id: '5',
    userId: 'U5',
    name: 'Omar Al-Mansour',
    email: 'omar@gulflands.com',
    phone: '+96599123456',
    subscriptionTier: 'enterprise',
    listingsCount: 58,
    dealsClosed: 15,
    avgResponseTime: 0.8,
    rating: 5.0,
    createdAt: '2022-11-05',
    active: false,
  },
];

const subscriptionColors: Record<SubscriptionTier, string> = {
  free: 'bg-gray-500',
  pro: 'bg-blue-500',
  enterprise: 'bg-amber-500',
};

export default function UsersPage() {
  const [sorting, setSorting] = useState<SortingState>([]);
  const [searchQuery, setSearchQuery] = useState('');
  const [isAddDialogOpen, setIsAddDialogOpen] = useState(false);
  const [selectedAgent, setSelectedAgent] = useState<Agent | null>(null);
  const [isEditDialogOpen, setIsEditDialogOpen] = useState(false);

  const columns: ColumnDef<Agent>[] = [
    {
      accessorKey: 'name',
      header: ({ column }) => (
        <Button variant="ghost" onClick={() => column.toggleSorting(column.getIsSorted() === 'asc')} className="-ml-4">
          Agent
          <ArrowUpDown className="ml-2 h-4 w-4" />
        </Button>
      ),
      cell: ({ row }) => (
        <div className="flex items-center gap-3">
          <Avatar className="h-10 w-10">
            <AvatarImage src={row.original.avatar} />
            <AvatarFallback className="bg-primary text-primary-foreground">
              {row.original.name.split(' ').map((n) => n[0]).join('')}
            </AvatarFallback>
          </Avatar>
          <div>
            <div className="flex items-center gap-2">
              <p className="font-medium">{row.original.name}</p>
              {!row.original.active && (
                <Badge variant="secondary" className="text-xs">Inactive</Badge>
              )}
            </div>
            <p className="text-sm text-muted-foreground">{row.original.email}</p>
          </div>
        </div>
      ),
    },
    {
      accessorKey: 'subscriptionTier',
      header: 'Plan',
      cell: ({ row }) => (
        <Badge className={`${subscriptionColors[row.original.subscriptionTier]} text-white capitalize`}>
          {row.original.subscriptionTier}
        </Badge>
      ),
    },
    {
      accessorKey: 'listingsCount',
      header: ({ column }) => (
        <Button variant="ghost" onClick={() => column.toggleSorting(column.getIsSorted() === 'asc')} className="-ml-4">
          Listings
          <ArrowUpDown className="ml-2 h-4 w-4" />
        </Button>
      ),
      cell: ({ row }) => (
        <div className="flex items-center gap-2">
          <span className="font-medium">{row.original.listingsCount}</span>
        </div>
      ),
    },
    {
      accessorKey: 'dealsClosed',
      header: ({ column }) => (
        <Button variant="ghost" onClick={() => column.toggleSorting(column.getIsSorted() === 'asc')} className="-ml-4">
          Deals
          <ArrowUpDown className="ml-2 h-4 w-4" />
        </Button>
      ),
      cell: ({ row }) => <span className="font-medium text-emerald-600">{row.original.dealsClosed}</span>,
    },
    {
      accessorKey: 'avgResponseTime',
      header: 'Response',
      cell: ({ row }) => (
        <div className="flex items-center gap-2">
          <span className={row.original.avgResponseTime < 2 ? 'text-emerald-600' : row.original.avgResponseTime < 4 ? 'text-amber-600' : 'text-red-600'}>
            {row.original.avgResponseTime}h
          </span>
        </div>
      ),
    },
    {
      accessorKey: 'rating',
      header: ({ column }) => (
        <Button variant="ghost" onClick={() => column.toggleSorting(column.getIsSorted() === 'asc')} className="-ml-4">
          Rating
          <ArrowUpDown className="ml-2 h-4 w-4" />
        </Button>
      ),
      cell: ({ row }) => (
        <div className="flex items-center gap-1">
          <Star className="h-4 w-4 fill-amber-500 text-amber-500" />
          <span>{row.original.rating.toFixed(1)}</span>
        </div>
      ),
    },
    {
      id: 'actions',
      cell: ({ row }) => {
        const agent = row.original;
        return (
          <DropdownMenu>
            <DropdownMenuTrigger asChild>
              <Button variant="ghost" size="icon">
                <MoreHorizontal className="h-4 w-4" />
              </Button>
            </DropdownMenuTrigger>
            <DropdownMenuContent align="end">
              <DropdownMenuLabel>Actions</DropdownMenuLabel>
              <DropdownMenuItem onClick={() => {
                setSelectedAgent(agent);
                setIsEditDialogOpen(true);
              }}>
                <Pencil className="mr-2 h-4 w-4" />
                Edit Agent
              </DropdownMenuItem>
              <DropdownMenuItem>
                <Activity className="mr-2 h-4 w-4" />
                View Activity
              </DropdownMenuItem>
              <DropdownMenuSeparator />
              <DropdownMenuItem className="text-destructive">
                <Trash2 className="mr-2 h-4 w-4" />
                Deactivate
              </DropdownMenuItem>
            </DropdownMenuContent>
          </DropdownMenu>
        );
      },
    },
  ];

  const filteredData = mockAgents.filter((agent) =>
    agent.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
    agent.email.toLowerCase().includes(searchQuery.toLowerCase())
  );

  const table = useReactTable({
    data: filteredData,
    columns,
    state: { sorting },
    onSortingChange: setSorting,
    getCoreRowModel: getCoreRowModel(),
    getPaginationRowModel: getPaginationRowModel(),
    getSortedRowModel: getSortedRowModel(),
  });

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold">User Management</h1>
          <p className="text-muted-foreground">Manage agents and subscription tiers</p>
        </div>
        <Dialog open={isAddDialogOpen} onOpenChange={setIsAddDialogOpen}>
          <DialogTrigger asChild>
            <Button className="bg-[#C9A227] hover:bg-[#D4B23E]">
              <Plus className="mr-2 h-4 w-4" />
              Add Agent
            </Button>
          </DialogTrigger>
          <DialogContent>
            <DialogHeader>
              <DialogTitle>Add New Agent</DialogTitle>
              <DialogDescription>Create a new agent account</DialogDescription>
            </DialogHeader>
            <AgentForm onClose={() => setIsAddDialogOpen(false)} />
          </DialogContent>
        </Dialog>
      </div>

      <div className="grid gap-4 md:grid-cols-4">
        <Card>
          <CardContent className="pt-6">
            <div className="flex items-center gap-3">
              <div className="rounded-lg bg-blue-500/10 p-2">
                <Activity className="h-5 w-5 text-blue-500" />
              </div>
              <div>
                <p className="text-2xl font-bold">{mockAgents.filter(a => a.active).length}</p>
                <p className="text-sm text-muted-foreground">Active Agents</p>
              </div>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="pt-6">
            <div className="flex items-center gap-3">
              <div className="rounded-lg bg-amber-500/10 p-2">
                <Shield className="h-5 w-5 text-amber-500" />
              </div>
              <div>
                <p className="text-2xl font-bold">{filteredData.length}</p>
                <p className="text-sm text-muted-foreground">Total Agents</p>
              </div>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="pt-6">
            <div className="flex items-center gap-3">
              <div className="rounded-lg bg-emerald-500/10 p-2">
                <TrendingUp className="h-5 w-5 text-emerald-500" />
              </div>
              <div>
                <p className="text-2xl font-bold">{mockAgents.reduce((acc, a) => acc + a.dealsClosed, 0)}</p>
                <p className="text-sm text-muted-foreground">Total Deals</p>
              </div>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="pt-6">
            <div className="flex items-center gap-3">
              <div className="rounded-lg bg-purple-500/10 p-2">
                <Star className="h-5 w-5 text-purple-500" />
              </div>
              <div>
                <p className="text-2xl font-bold">{(mockAgents.reduce((acc, a) => acc + a.rating, 0) / mockAgents.length).toFixed(1)}</p>
                <p className="text-sm text-muted-foreground">Avg Rating</p>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>

      <Card>
        <CardHeader>
          <div className="flex flex-col gap-4 md:flex-row md:items-center md:justify-between">
            <div>
              <CardTitle>All Agents</CardTitle>
              <CardDescription>{filteredData.length} agents registered</CardDescription>
            </div>
            <Input
              placeholder="Search agents..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="w-full md:w-64"
            />
          </div>
        </CardHeader>
        <CardContent>
          <div className="rounded-md border">
            <Table>
              <TableHeader>
                {table.getHeaderGroups().map((headerGroup) => (
                  <TableRow key={headerGroup.id}>
                    {headerGroup.headers.map((header) => (
                      <TableHead key={header.id}>
                        {header.isPlaceholder
                          ? null
                          : flexRender(header.column.columnDef.header, header.getContext())}
                      </TableHead>
                    ))}
                  </TableRow>
                ))}
              </TableHeader>
              <TableBody>
                {table.getRowModel().rows?.length ? (
                  table.getRowModel().rows.map((row) => (
                    <TableRow key={row.id}>
                      {row.getVisibleCells().map((cell) => (
                        <TableCell key={cell.id}>
                          {flexRender(cell.column.columnDef.cell, cell.getContext())}
                        </TableCell>
                      ))}
                    </TableRow>
                  ))
                ) : (
                  <TableRow>
                    <TableCell colSpan={columns.length} className="h-24 text-center">
                      No agents found.
                    </TableCell>
                  </TableRow>
                )}
              </TableBody>
            </Table>
          </div>
          <div className="flex items-center justify-between py-4">
            <div className="text-sm text-muted-foreground">
              Page {table.getState().pagination.pageIndex + 1} of {table.getPageCount()}
            </div>
            <div className="flex gap-2">
              <Button variant="outline" size="sm" onClick={() => table.previousPage()} disabled={!table.getCanPreviousPage()}>
                Previous
              </Button>
              <Button variant="outline" size="sm" onClick={() => table.nextPage()} disabled={!table.getCanNextPage()}>
                Next
              </Button>
            </div>
          </div>
        </CardContent>
      </Card>

      <Dialog open={isEditDialogOpen} onOpenChange={setIsEditDialogOpen}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Edit Agent</DialogTitle>
            <DialogDescription>Update agent information</DialogDescription>
          </DialogHeader>
          {selectedAgent && <AgentForm agent={selectedAgent} onClose={() => setIsEditDialogOpen(false)} />}
        </DialogContent>
      </Dialog>
    </div>
  );
}

function AgentForm({ agent, onClose }: { agent?: Agent; onClose: () => void }) {
  const [formData, setFormData] = useState({
    name: agent?.name || '',
    email: agent?.email || '',
    phone: agent?.phone || '',
    subscriptionTier: agent?.subscriptionTier || 'free',
  });

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    toast.success(agent ? 'Agent updated successfully' : 'Agent created successfully');
    onClose();
  };

  return (
    <form onSubmit={handleSubmit} className="space-y-4">
      <div className="space-y-2">
        <Label htmlFor="name">Full Name</Label>
        <Input
          id="name"
          value={formData.name}
          onChange={(e) => setFormData({ ...formData, name: e.target.value })}
          required
        />
      </div>
      <div className="space-y-2">
        <Label htmlFor="email">Email</Label>
        <Input
          id="email"
          type="email"
          value={formData.email}
          onChange={(e) => setFormData({ ...formData, email: e.target.value })}
          required
        />
      </div>
      <div className="space-y-2">
        <Label htmlFor="phone">Phone Number</Label>
        <Input
          id="phone"
          value={formData.phone}
          onChange={(e) => setFormData({ ...formData, phone: e.target.value })}
          required
        />
      </div>
      <div className="space-y-2">
        <Label htmlFor="tier">Subscription Tier</Label>
        <Select value={formData.subscriptionTier} onValueChange={(v) => setFormData({ ...formData, subscriptionTier: v as SubscriptionTier })}>
          <SelectTrigger>
            <SelectValue />
          </SelectTrigger>
          <SelectContent>
            <SelectItem value="free">Free</SelectItem>
            <SelectItem value="pro">Pro</SelectItem>
            <SelectItem value="enterprise">Enterprise</SelectItem>
          </SelectContent>
        </Select>
      </div>
      <DialogFooter className="mt-6">
        <Button type="button" variant="outline" onClick={onClose}>
          Cancel
        </Button>
        <Button type="submit" className="bg-[#C9A227] hover:bg-[#D4B23E]">
          {agent ? 'Update Agent' : 'Create Agent'}
        </Button>
      </DialogFooter>
    </form>
  );
}
