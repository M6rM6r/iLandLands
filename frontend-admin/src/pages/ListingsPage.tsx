import { useState, useEffect } from 'react';
import {
  ColumnDef,
  flexRender,
  getCoreRowModel,
  useReactTable,
  getPaginationRowModel,
  getSortedRowModel,
  getFilteredRowModel,
  SortingState,
  ColumnFiltersState,
} from '@tanstack/react-table';
import { ArrowUpDown, MoreHorizontal, Plus, Eye, Pencil, Trash2, Star } from 'lucide-react';
import { Button } from '../components/ui/button';
import { Input } from '../components/ui/input';
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '../components/ui/table';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '../components/ui/card';
import { Badge } from '../components/ui/badge';
import { Checkbox } from '../components/ui/checkbox';
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
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from '../components/ui/dialog';
import { Label } from '../components/ui/label';
import { Textarea } from '../components/ui/textarea';
import { Switch } from '../components/ui/switch';
import { toast } from 'sonner';
import type { Listing, ListingStatus, GCCCountry } from '../lib/types';

type PropertyType = 'villa' | 'apartment' | 'land' | 'commercial' | 'penthouse';

const mockListings: Listing[] = [
  {
    id: '1',
    title: 'Luxury Villa in Palm Jumeirah',
    description: 'Stunning 5-bedroom villa with private beach access',
    price: 15000000,
    currency: 'AED',
    country: 'UAE',
    city: 'Dubai',
    address: 'Palm Jumeirah, Frond M',
    areaSqm: 850,
    bedrooms: 5,
    bathrooms: 6,
    propertyType: 'villa',
    status: 'approved',
    featured: true,
    images: ['https://images.pexels.com/photos/323780/pexels-photo-323780.jpeg?auto=compress&cs=tinysrgb&w=400'],
    agentId: '1',
    agentName: 'Ahmed Hassan',
    createdAt: '2024-06-01T10:00:00Z',
    updatedAt: '2024-06-15T14:30:00Z',
    views: 1245,
    inquiries: 28,
  },
  {
    id: '2',
    title: 'Modern Penthouse in Riyadh',
    description: 'Contemporary penthouse with panoramic city views',
    price: 8500000,
    currency: 'SAR',
    country: 'Saudi Arabia',
    city: 'Riyadh',
    address: 'King Fahd Road, Tower 5',
    areaSqm: 420,
    bedrooms: 3,
    bathrooms: 4,
    propertyType: 'penthouse',
    status: 'pending',
    featured: false,
    images: ['https://images.pexels.com/photos/259588/pexels-photo-259588.jpeg?auto=compress&cs=tinysrgb&w=400'],
    agentId: '2',
    agentName: 'Fatima Al-Rashid',
    createdAt: '2024-06-10T09:00:00Z',
    updatedAt: '2024-06-10T09:00:00Z',
    views: 567,
    inquiries: 12,
  },
  {
    id: '3',
    title: 'Waterfront Estate in Doha',
    description: 'Exclusive waterfront property with private marina',
    price: 22000000,
    currency: 'QAR',
    country: 'Qatar',
    city: 'Doha',
    address: 'The Pearl, Viva Bahriya',
    areaSqm: 1200,
    bedrooms: 6,
    bathrooms: 8,
    propertyType: 'villa',
    status: 'approved',
    featured: true,
    images: ['https://images.pexels.com/photos/186077/pexels-photo-186077.jpeg?auto=compress&cs=tinysrgb&w=400'],
    agentId: '1',
    agentName: 'Ahmed Hassan',
    createdAt: '2024-05-20T11:00:00Z',
    updatedAt: '2024-06-12T16:00:00Z',
    views: 2340,
    inquiries: 45,
  },
  {
    id: '4',
    title: 'Commercial Land in Bahrain',
    description: 'Prime commercial plot in Business Bay',
    price: 5000000,
    currency: 'BHD',
    country: 'Bahrain',
    city: 'Manama',
    address: 'Financial Harbour, Block 428',
    areaSqm: 2500,
    bedrooms: 0,
    bathrooms: 0,
    propertyType: 'land',
    status: 'sold',
    featured: false,
    images: ['https://images.pexels.com/photos/1396122/pexels-photo-1396122.jpeg?auto=compress&cs=tinysrgb&w=400'],
    agentId: '3',
    agentName: 'Mohammed Khalil',
    createdAt: '2024-05-01T08:00:00Z',
    updatedAt: '2024-06-05T10:00:00Z',
    views: 890,
    inquiries: 23,
  },
  {
    id: '5',
    title: 'Luxury Apartment in Kuwait',
    description: 'High-end apartment in exclusive neighborhood',
    price: 3200000,
    currency: 'KWD',
    country: 'Kuwait',
    city: 'Kuwait City',
    address: 'Salhiya, Tower B',
    areaSqm: 280,
    bedrooms: 2,
    bathrooms: 3,
    propertyType: 'apartment',
    status: 'approved',
    featured: false,
    images: ['https://images.pexels.com/photos/259588/pexels-photo-259588.jpeg?auto=compress&cs=tinysrgb&w=400'],
    agentId: '2',
    agentName: 'Fatima Al-Rashid',
    createdAt: '2024-06-05T14:00:00Z',
    updatedAt: '2024-06-14T11:00:00Z',
    views: 432,
    inquiries: 8,
  },
];

const statusColors: Record<ListingStatus, string> = {
  pending: 'bg-yellow-500/10 text-yellow-600 border-yellow-500/20',
  approved: 'bg-emerald-500/10 text-emerald-600 border-emerald-500/20',
  sold: 'bg-blue-500/10 text-blue-600 border-blue-500/20',
  rejected: 'bg-red-500/10 text-red-600 border-red-500/20',
};

const countries: GCCCountry[] = ['UAE', 'Saudi Arabia', 'Qatar', 'Bahrain', 'Kuwait', 'Oman'];

export default function ListingsPage() {
  const [sorting, setSorting] = useState<SortingState>([]);
  const [columnFilters, setColumnFilters] = useState<ColumnFiltersState>([]);
  const [rowSelection, setRowSelection] = useState({});
  const [searchQuery, setSearchQuery] = useState('');
  const [statusFilter, setStatusFilter] = useState<ListingStatus | 'all'>('all');
  const [countryFilter, setCountryFilter] = useState<GCCCountry | 'all'>('all');

  const [isAddDialogOpen, setIsAddDialogOpen] = useState(false);
  const [isEditDialogOpen, setIsEditDialogOpen] = useState(false);
  const [isDeleteDialogOpen, setIsDeleteDialogOpen] = useState(false);
  const [selectedListing, setSelectedListing] = useState<Listing | null>(null);

  const columns: ColumnDef<Listing>[] = [
    {
      id: 'select',
      header: ({ table }) => (
        <Checkbox
          checked={table.getIsAllPageRowsSelected()}
          onCheckedChange={(value) => table.toggleAllPageRowsSelected(!!value)}
          aria-label="Select all"
        />
      ),
      cell: ({ row }) => (
        <Checkbox
          checked={row.getIsSelected()}
          onCheckedChange={(value) => row.toggleSelected(!!value)}
          aria-label="Select row"
        />
      ),
      enableSorting: false,
      enableHiding: false,
    },
    {
      accessorKey: 'images',
      header: 'Image',
      cell: ({ row }) => (
        <img
          src={row.original.images[0] || '/placeholder.jpg'}
          alt={row.original.title}
          className="h-12 w-16 rounded-md object-cover"
        />
      ),
    },
    {
      accessorKey: 'title',
      header: ({ column }) => (
        <Button
          variant="ghost"
          onClick={() => column.toggleSorting(column.getIsSorted() === 'asc')}
          className="-ml-4"
        >
          Title
          <ArrowUpDown className="ml-2 h-4 w-4" />
        </Button>
      ),
      cell: ({ row }) => (
        <div>
          <div className="flex items-center gap-2">
            <span className="font-medium">{row.original.title}</span>
            {row.original.featured && (
              <Star className="h-4 w-4 fill-amber-500 text-amber-500" />
            )}
          </div>
          <div className="text-sm text-muted-foreground">{row.original.city}, {row.original.country}</div>
        </div>
      ),
    },
    {
      accessorKey: 'price',
      header: ({ column }) => (
        <Button
          variant="ghost"
          onClick={() => column.toggleSorting(column.getIsSorted() === 'asc')}
          className="-ml-4"
        >
          Price
          <ArrowUpDown className="ml-2 h-4 w-4" />
        </Button>
      ),
      cell: ({ row }) => {
        const price = row.original.price;
        const formatted = new Intl.NumberFormat('en-US', {
          style: 'currency',
          currency: row.original.currency,
          maximumFractionDigits: 0,
        }).format(price);
        return <span className="font-medium">{formatted}</span>;
      },
    },
    {
      accessorKey: 'propertyType',
      header: 'Type',
      cell: ({ row }) => (
        <Badge variant="outline" className="capitalize">
          {row.original.propertyType}
        </Badge>
      ),
    },
    {
      accessorKey: 'areaSqm',
      header: 'Area',
      cell: ({ row }) => <span>{row.original.areaSqm.toLocaleString()} m²</span>,
    },
    {
      accessorKey: 'status',
      header: 'Status',
      cell: ({ row }) => (
        <Badge variant="outline" className={statusColors[row.original.status]}>
          {row.original.status}
        </Badge>
      ),
    },
    {
      accessorKey: 'views',
      header: 'Views',
      cell: ({ row }) => <span className="text-muted-foreground">{row.original.views.toLocaleString()}</span>,
    },
    {
      accessorKey: 'inquiries',
      header: 'Inquiries',
      cell: ({ row }) => <span className="text-muted-foreground">{row.original.inquiries}</span>,
    },
    {
      id: 'actions',
      cell: ({ row }) => {
        const listing = row.original;
        return (
          <DropdownMenu>
            <DropdownMenuTrigger asChild>
              <Button variant="ghost" size="icon">
                <MoreHorizontal className="h-4 w-4" />
              </Button>
            </DropdownMenuTrigger>
            <DropdownMenuContent align="end">
              <DropdownMenuLabel>Actions</DropdownMenuLabel>
              <DropdownMenuItem onClick={() => window.open(`/listing/${listing.id}`, '_blank')}>
                <Eye className="mr-2 h-4 w-4" />
                View Details
              </DropdownMenuItem>
              <DropdownMenuItem onClick={() => {
                setSelectedListing(listing);
                setIsEditDialogOpen(true);
              }}>
                <Pencil className="mr-2 h-4 w-4" />
                Edit
              </DropdownMenuItem>
              <DropdownMenuSeparator />
              <DropdownMenuItem onClick={() => {
                setSelectedListing(listing);
                setIsDeleteDialogOpen(true);
              }} className="text-destructive">
                <Trash2 className="mr-2 h-4 w-4" />
                Delete
              </DropdownMenuItem>
            </DropdownMenuContent>
          </DropdownMenu>
        );
      },
    },
  ];

  const filteredData = mockListings.filter((listing) => {
    const matchesSearch = listing.title.toLowerCase().includes(searchQuery.toLowerCase()) ||
      listing.city.toLowerCase().includes(searchQuery.toLowerCase());
    const matchesStatus = statusFilter === 'all' || listing.status === statusFilter;
    const matchesCountry = countryFilter === 'all' || listing.country === countryFilter;
    return matchesSearch && matchesStatus && matchesCountry;
  });

  const table = useReactTable({
    data: filteredData,
    columns,
    state: {
      sorting,
      columnFilters,
      rowSelection,
    },
    onSortingChange: setSorting,
    onColumnFiltersChange: setColumnFilters,
    onRowSelectionChange: setRowSelection,
    getCoreRowModel: getCoreRowModel(),
    getPaginationRowModel: getPaginationRowModel(),
    getSortedRowModel: getSortedRowModel(),
    getFilteredRowModel: getFilteredRowModel(),
  });

  const handleBulkAction = (action: 'approve' | 'reject' | 'delete') => {
    const selectedRows = table.getFilteredSelectedRowModel().rows;
    toast.success(`${selectedRows.length} listings ${action}d`);
    setRowSelection({});
  };

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold">Listings Management</h1>
          <p className="text-muted-foreground">Manage property listings across all regions</p>
        </div>
        <Dialog open={isAddDialogOpen} onOpenChange={setIsAddDialogOpen}>
          <DialogTrigger asChild>
            <Button className="bg-[#C9A227] hover:bg-[#D4B23E]">
              <Plus className="mr-2 h-4 w-4" />
              Add Listing
            </Button>
          </DialogTrigger>
          <DialogContent className="max-w-2xl max-h-[90vh] overflow-y-auto">
            <DialogHeader>
              <DialogTitle>Add New Listing</DialogTitle>
              <DialogDescription>Create a new property listing</DialogDescription>
            </DialogHeader>
            <ListingForm onClose={() => setIsAddDialogOpen(false)} />
          </DialogContent>
        </Dialog>
      </div>

      <Card>
        <CardHeader>
          <div className="flex flex-col gap-4 md:flex-row md:items-center md:justify-between">
            <div>
              <CardTitle>All Listings</CardTitle>
              <CardDescription>{filteredData.length} listings found</CardDescription>
            </div>
            <div className="flex flex-col gap-2 md:flex-row md:items-center">
              <Input
                placeholder="Search listings..."
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                className="w-full md:w-64"
              />
              <Select value={statusFilter} onValueChange={(v) => setStatusFilter(v as ListingStatus | 'all')}>
                <SelectTrigger className="w-full md:w-36">
                  <SelectValue placeholder="Status" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="all">All Status</SelectItem>
                  <SelectItem value="pending">Pending</SelectItem>
                  <SelectItem value="approved">Approved</SelectItem>
                  <SelectItem value="sold">Sold</SelectItem>
                  <SelectItem value="rejected">Rejected</SelectItem>
                </SelectContent>
              </Select>
              <Select value={countryFilter} onValueChange={(v) => setCountryFilter(v as GCCCountry | 'all')}>
                <SelectTrigger className="w-full md:w-36">
                  <SelectValue placeholder="Country" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="all">All Countries</SelectItem>
                  {countries.map((country) => (
                    <SelectItem key={country} value={country}>{country}</SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
          </div>
        </CardHeader>
        <CardContent>
          {Object.keys(rowSelection).length > 0 && (
            <div className="mb-4 flex items-center gap-2 rounded-lg bg-muted p-3">
              <span className="text-sm font-medium">
                {Object.keys(rowSelection).length} selected
              </span>
              <Button size="sm" variant="outline" onClick={() => handleBulkAction('approve')}>
                Approve
              </Button>
              <Button size="sm" variant="outline" onClick={() => handleBulkAction('reject')}>
                Reject
              </Button>
              <Button size="sm" variant="destructive" onClick={() => handleBulkAction('delete')}>
                Delete
              </Button>
            </div>
          )}
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
                    <TableRow key={row.id} data-state={row.getIsSelected() && 'selected'}>
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
                      No listings found.
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
              <Button
                variant="outline"
                size="sm"
                onClick={() => table.previousPage()}
                disabled={!table.getCanPreviousPage()}
              >
                Previous
              </Button>
              <Button
                variant="outline"
                size="sm"
                onClick={() => table.nextPage()}
                disabled={!table.getCanNextPage()}
              >
                Next
              </Button>
            </div>
          </div>
        </CardContent>
      </Card>

      <Dialog open={isEditDialogOpen} onOpenChange={setIsEditDialogOpen}>
        <DialogContent className="max-w-2xl max-h-[90vh] overflow-y-auto">
          <DialogHeader>
            <DialogTitle>Edit Listing</DialogTitle>
            <DialogDescription>Update property listing details</DialogDescription>
          </DialogHeader>
          {selectedListing && <ListingForm listing={selectedListing} onClose={() => setIsEditDialogOpen(false)} />}
        </DialogContent>
      </Dialog>

      <Dialog open={isDeleteDialogOpen} onOpenChange={setIsDeleteDialogOpen}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Delete Listing</DialogTitle>
            <DialogDescription>
              Are you sure you want to delete "{selectedListing?.title}"? This action cannot be undone.
            </DialogDescription>
          </DialogHeader>
          <DialogFooter>
            <Button variant="outline" onClick={() => setIsDeleteDialogOpen(false)}>
              Cancel
            </Button>
            <Button variant="destructive" onClick={() => {
              toast.success('Listing deleted successfully');
              setIsDeleteDialogOpen(false);
            }}>
              Delete
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
}

function ListingForm({ listing, onClose }: { listing?: Listing; onClose: () => void }) {
  const [formData, setFormData] = useState<{
    title: string;
    description: string;
    price: string;
    currency: string;
    country: GCCCountry;
    city: string;
    address: string;
    areaSqm: string;
    bedrooms: string;
    bathrooms: string;
    propertyType: PropertyType;
    featured: boolean;
    status: ListingStatus;
  }>({
    title: listing?.title || '',
    description: listing?.description || '',
    price: listing?.price?.toString() || '',
    currency: listing?.currency || 'AED',
    country: listing?.country || 'UAE',
    city: listing?.city || '',
    address: listing?.address || '',
    areaSqm: listing?.areaSqm?.toString() || '',
    bedrooms: listing?.bedrooms?.toString() || '',
    bathrooms: listing?.bathrooms?.toString() || '',
    propertyType: listing?.propertyType || 'villa',
    featured: listing?.featured || false,
    status: listing?.status || 'pending',
  });

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    toast.success(listing ? 'Listing updated successfully' : 'Listing created successfully');
    onClose();
  };

  return (
    <form onSubmit={handleSubmit} className="space-y-4">
      <div className="grid gap-4 md:grid-cols-2">
        <div className="space-y-2 md:col-span-2">
          <Label htmlFor="title">Title</Label>
          <Input
            id="title"
            value={formData.title}
            onChange={(e) => setFormData({ ...formData, title: e.target.value })}
            required
          />
        </div>
        <div className="space-y-2 md:col-span-2">
          <Label htmlFor="description">Description</Label>
          <Textarea
            id="description"
            value={formData.description}
            onChange={(e) => setFormData({ ...formData, description: e.target.value })}
            rows={4}
          />
        </div>
        <div className="space-y-2">
          <Label htmlFor="price">Price</Label>
          <Input
            id="price"
            type="number"
            value={formData.price}
            onChange={(e) => setFormData({ ...formData, price: e.target.value })}
            required
          />
        </div>
        <div className="space-y-2">
          <Label htmlFor="currency">Currency</Label>
          <Select value={formData.currency} onValueChange={(v) => setFormData({ ...formData, currency: v })}>
            <SelectTrigger>
              <SelectValue />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="AED">AED - UAE Dirham</SelectItem>
              <SelectItem value="SAR">SAR - Saudi Riyal</SelectItem>
              <SelectItem value="QAR">QAR - Qatari Riyal</SelectItem>
              <SelectItem value="BHD">BHD - Bahraini Dinar</SelectItem>
              <SelectItem value="KWD">KWD - Kuwaiti Dinar</SelectItem>
              <SelectItem value="OMR">OMR - Omani Rial</SelectItem>
            </SelectContent>
          </Select>
        </div>
        <div className="space-y-2">
          <Label htmlFor="country">Country</Label>
          <Select value={formData.country} onValueChange={(v) => setFormData({ ...formData, country: v as GCCCountry })}>
            <SelectTrigger>
              <SelectValue />
            </SelectTrigger>
            <SelectContent>
              {countries.map((country) => (
                <SelectItem key={country} value={country}>{country}</SelectItem>
              ))}
            </SelectContent>
          </Select>
        </div>
        <div className="space-y-2">
          <Label htmlFor="city">City</Label>
          <Input
            id="city"
            value={formData.city}
            onChange={(e) => setFormData({ ...formData, city: e.target.value })}
            required
          />
        </div>
        <div className="space-y-2 md:col-span-2">
          <Label htmlFor="address">Address</Label>
          <Input
            id="address"
            value={formData.address}
            onChange={(e) => setFormData({ ...formData, address: e.target.value })}
            required
          />
        </div>
        <div className="space-y-2">
          <Label htmlFor="areaSqm">Area (m²)</Label>
          <Input
            id="areaSqm"
            type="number"
            value={formData.areaSqm}
            onChange={(e) => setFormData({ ...formData, areaSqm: e.target.value })}
            required
          />
        </div>
        <div className="space-y-2">
          <Label htmlFor="propertyType">Property Type</Label>
          <Select value={formData.propertyType} onValueChange={(v) => setFormData({ ...formData, propertyType: v as 'villa' | 'apartment' | 'land' | 'commercial' | 'penthouse' })}>
            <SelectTrigger>
              <SelectValue />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="villa">Villa</SelectItem>
              <SelectItem value="apartment">Apartment</SelectItem>
              <SelectItem value="penthouse">Penthouse</SelectItem>
              <SelectItem value="land">Land</SelectItem>
              <SelectItem value="commercial">Commercial</SelectItem>
            </SelectContent>
          </Select>
        </div>
        <div className="space-y-2">
          <Label htmlFor="bedrooms">Bedrooms</Label>
          <Input
            id="bedrooms"
            type="number"
            value={formData.bedrooms}
            onChange={(e) => setFormData({ ...formData, bedrooms: e.target.value })}
          />
        </div>
        <div className="space-y-2">
          <Label htmlFor="bathrooms">Bathrooms</Label>
          <Input
            id="bathrooms"
            type="number"
            value={formData.bathrooms}
            onChange={(e) => setFormData({ ...formData, bathrooms: e.target.value })}
          />
        </div>
        <div className="space-y-2">
          <Label htmlFor="status">Status</Label>
          <Select value={formData.status} onValueChange={(v) => setFormData({ ...formData, status: v as ListingStatus })}>
            <SelectTrigger>
              <SelectValue />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="pending">Pending</SelectItem>
              <SelectItem value="approved">Approved</SelectItem>
              <SelectItem value="sold">Sold</SelectItem>
              <SelectItem value="rejected">Rejected</SelectItem>
            </SelectContent>
          </Select>
        </div>
        <div className="flex items-center space-x-2">
          <Switch
            id="featured"
            checked={formData.featured}
            onCheckedChange={(checked) => setFormData({ ...formData, featured: checked })}
          />
          <Label htmlFor="featured">Featured Listing</Label>
        </div>
      </div>
      <DialogFooter className="mt-6">
        <Button type="button" variant="outline" onClick={onClose}>
          Cancel
        </Button>
        <Button type="submit" className="bg-[#C9A227] hover:bg-[#D4B23E]">
          {listing ? 'Update Listing' : 'Create Listing'}
        </Button>
      </DialogFooter>
    </form>
  );
}
