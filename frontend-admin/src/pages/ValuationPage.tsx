import { useState } from 'react';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '../components/ui/card';
import { Button } from '../components/ui/button';
import { Input } from '../components/ui/input';
import { Label } from '../components/ui/label';
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '../components/ui/select';
import { Badge } from '../components/ui/badge';
import {
  LineChart,
  Line,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
} from 'recharts';
import { Calculator, MapPin, Building2, Waves, Loader2, TrendingUp, AlertCircle, CheckCircle } from 'lucide-react';
import { toast } from 'sonner';
import type { GCCCountry, ValuationResult } from '../lib/types';

const valuationSchema = z.object({
  country: z.string().min(1, 'Country is required'),
  city: z.string().min(1, 'City is required'),
  areaSqm: z.number().min(1, 'Area is required'),
  zoning: z.string().min(1, 'Zoning is required'),
  coastalDistance: z.number().min(0, 'Coastal distance is required'),
  yearBuilt: z.number().min(1900).max(new Date().getFullYear()).optional(),
});

type ValuationFormData = z.infer<typeof valuationSchema>;

const countries: GCCCountry[] = ['UAE', 'Saudi Arabia', 'Qatar', 'Bahrain', 'Kuwait', 'Oman'];
const zoningTypes = ['residential', 'commercial', 'mixed_use', 'industrial'];

const mockValuationResult: ValuationResult = {
  estimatedValue: 18500000,
  minEstimate: 16500000,
  maxEstimate: 20500000,
  confidence: 87,
  comparables: [
    {
      id: '1',
      title: 'Luxury Villa - Palm Jumeirah',
      price: 19000000,
      areaSqm: 820,
      pricePerSqm: 23171,
      distance: 0.5,
      address: 'Palm Jumeirah, Frond L',
      soldDate: '2024-04-15',
    },
    {
      id: '2',
      title: 'Modern Estate - Emirates Hills',
      price: 17500000,
      areaSqm: 780,
      pricePerSqm: 22436,
      distance: 2.1,
      address: 'Emirates Hills, Sector E',
      soldDate: '2024-03-20',
    },
    {
      id: '3',
      title: 'Waterfront Villa - Dubai Marina',
      price: 21000000,
      areaSqm: 900,
      pricePerSqm: 23333,
      distance: 1.8,
      address: 'Dubai Marina, Pier 5',
      soldDate: '2024-05-10',
    },
  ],
  priceTrend: [
    { month: 'Jan', avgPrice: 17500000, avgPricePerSqm: 21000 },
    { month: 'Feb', avgPrice: 17800000, avgPricePerSqm: 21400 },
    { month: 'Mar', avgPrice: 18000000, avgPricePerSqm: 21600 },
    { month: 'Apr', avgPrice: 18200000, avgPricePerSqm: 21900 },
    { month: 'May', avgPrice: 18400000, avgPricePerSqm: 22100 },
    { month: 'Jun', avgPrice: 18800000, avgPricePerSqm: 22600 },
  ],
  factors: [
    { name: 'Location Premium', impact: 15, description: 'Premium waterfront location adds significant value' },
    { name: 'Market Trend', impact: 8, description: 'Rising market trend in Dubai luxury segment' },
    { name: 'Size Factor', impact: 5, description: 'Large property size commands higher per-sqm prices' },
    { name: 'Age Premium', impact: -3, description: 'Slight discount for properties over 10 years old' },
  ],
};

const formatPrice = (price: number) => {
  return new Intl.NumberFormat('en-US', {
    style: 'currency',
    currency: 'AED',
    maximumFractionDigits: 0,
  }).format(price);
};

export default function ValuationPage() {
  const [isLoading, setIsLoading] = useState(false);
  const [result, setResult] = useState<ValuationResult | null>(null);

  const {
    register,
    handleSubmit,
    setValue,
    formState: { errors },
  } = useForm<ValuationFormData>({
    resolver: zodResolver(valuationSchema),
  });

  const onSubmit = async () => {
    setIsLoading(true);
    try {
      await new Promise((resolve) => setTimeout(resolve, 2000));
      setResult(mockValuationResult);
      toast.success('Valuation completed successfully');
    } catch {
      toast.error('Failed to get valuation');
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-3xl font-bold">Property Valuation Tool</h1>
        <p className="text-muted-foreground">Get AI-powered property valuations for GCC real estate</p>
      </div>

      <div className="grid gap-6 lg:grid-cols-3">
        <Card className="lg:col-span-1">
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <Calculator className="h-5 w-5" />
              Valuation Parameters
            </CardTitle>
            <CardDescription>Enter property details to get an estimate</CardDescription>
          </CardHeader>
          <CardContent>
            <form onSubmit={handleSubmit(onSubmit)} className="space-y-4">
              <div className="space-y-2">
                <Label htmlFor="country">Country</Label>
                <Select onValueChange={(v) => setValue('country', v)}>
                  <SelectTrigger>
                    <SelectValue placeholder="Select country" />
                  </SelectTrigger>
                  <SelectContent>
                    {countries.map((country) => (
                      <SelectItem key={country} value={country}>{country}</SelectItem>
                    ))}
                  </SelectContent>
                </Select>
                {errors.country && <p className="text-sm text-destructive">{errors.country.message}</p>}
              </div>

              <div className="space-y-2">
                <Label htmlFor="city">City</Label>
                <div className="relative">
                  <MapPin className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
                  <Input
                    id="city"
                    placeholder="e.g., Dubai, Riyadh, Doha"
                    className="pl-10"
                    {...register('city')}
                  />
                </div>
                {errors.city && <p className="text-sm text-destructive">{errors.city.message}</p>}
              </div>

              <div className="space-y-2">
                <Label htmlFor="areaSqm">Area (m²)</Label>
                <div className="relative">
                  <Building2 className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
                  <Input
                    id="areaSqm"
                    type="number"
                    placeholder="Property area"
                    className="pl-10"
                    {...register('areaSqm', { valueAsNumber: true })}
                  />
                </div>
                {errors.areaSqm && <p className="text-sm text-destructive">{errors.areaSqm.message}</p>}
              </div>

              <div className="space-y-2">
                <Label htmlFor="zoning">Zoning Type</Label>
                <Select onValueChange={(v) => setValue('zoning', v)}>
                  <SelectTrigger>
                    <SelectValue placeholder="Select zoning" />
                  </SelectTrigger>
                  <SelectContent>
                    {zoningTypes.map((type) => (
                      <SelectItem key={type} value={type} className="capitalize">
                        {type.replace('_', ' ')}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
                {errors.zoning && <p className="text-sm text-destructive">{errors.zoning.message}</p>}
              </div>

              <div className="space-y-2">
                <Label htmlFor="coastalDistance">Coastal Distance (km)</Label>
                <div className="relative">
                  <Waves className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
                  <Input
                    id="coastalDistance"
                    type="number"
                    step="0.1"
                    placeholder="Distance to coast"
                    className="pl-10"
                    {...register('coastalDistance', { valueAsNumber: true })}
                  />
                </div>
                {errors.coastalDistance && <p className="text-sm text-destructive">{errors.coastalDistance.message}</p>}
              </div>

              <div className="space-y-2">
                <Label htmlFor="yearBuilt">Year Built (Optional)</Label>
                <Input
                  id="yearBuilt"
                  type="number"
                  placeholder="e.g., 2020"
                  {...register('yearBuilt', { valueAsNumber: true })}
                />
              </div>

              <Button
                type="submit"
                className="w-full bg-[#C9A227] hover:bg-[#D4B23E]"
                disabled={isLoading}
              >
                {isLoading ? (
                  <>
                    <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                    Calculating...
                  </>
                ) : (
                  <>
                    <Calculator className="mr-2 h-4 w-4" />
                    Get Valuation
                  </>
                )}
              </Button>
            </form>
          </CardContent>
        </Card>

        <div className="lg:col-span-2 space-y-6">
          {result ? (
            <>
              <Card>
                <CardHeader>
                  <CardTitle>Estimated Value</CardTitle>
                  <CardDescription>Based on comparable properties and market analysis</CardDescription>
                </CardHeader>
                <CardContent>
                  <div className="text-center mb-6">
                    <div className="text-5xl font-bold text-primary">{formatPrice(result.estimatedValue)}</div>
                    <div className="flex items-center justify-center gap-2 mt-2 text-muted-foreground">
                      <span>{formatPrice(result.minEstimate)}</span>
                      <span>-</span>
                      <span>{formatPrice(result.maxEstimate)}</span>
                    </div>
                    <div className="flex items-center justify-center gap-2 mt-4">
                      <Badge variant={result.confidence >= 80 ? 'default' : result.confidence >= 60 ? 'secondary' : 'outline'} className="gap-1">
                        {result.confidence >= 80 ? (
                          <CheckCircle className="h-3 w-3" />
                        ) : (
                          <AlertCircle className="h-3 w-3" />
                        )}
                        {result.confidence}% Confidence
                      </Badge>
                      <Badge variant="outline" className="gap-1">
                        <TrendingUp className="h-3 w-3" />
                        {Math.round(result.estimatedValue / 850)} AED/m²
                      </Badge>
                    </div>
                  </div>
                </CardContent>
              </Card>

              <Card>
                <CardHeader>
                  <CardTitle>Price Trend</CardTitle>
                  <CardDescription>Average property prices over the last 6 months</CardDescription>
                </CardHeader>
                <CardContent>
                  <div className="h-[250px]">
                    <ResponsiveContainer width="100%" height="100%">
                      <LineChart data={result.priceTrend}>
                        <CartesianGrid strokeDasharray="3 3" className="stroke-muted" />
                        <XAxis dataKey="month" className="text-xs" />
                        <YAxis className="text-xs" />
                        <Tooltip
                          contentStyle={{
                            backgroundColor: 'hsl(var(--card))',
                            border: '1px solid hsl(var(--border))',
                            borderRadius: '8px',
                          }}
                          formatter={(value: number) => formatPrice(value)}
                        />
                        <Line type="monotone" dataKey="avgPrice" stroke="#C9A227" strokeWidth={2} />
                      </LineChart>
                    </ResponsiveContainer>
                  </div>
                </CardContent>
              </Card>

              <Card>
                <CardHeader>
                  <CardTitle>Comparable Properties</CardTitle>
                  <CardDescription>Similar properties recently sold in the area</CardDescription>
                </CardHeader>
                <CardContent>
                  <div className="space-y-4">
                    {result.comparables.map((comp) => (
                      <div key={comp.id} className="flex items-start justify-between p-4 rounded-lg border">
                        <div>
                          <p className="font-medium">{comp.title}</p>
                          <p className="text-sm text-muted-foreground">{comp.address}</p>
                          <div className="flex items-center gap-4 mt-2 text-sm">
                            <span className="text-muted-foreground">{comp.areaSqm} m²</span>
                            <span className="text-muted-foreground">{comp.distance} km away</span>
                            <span className="text-muted-foreground">Sold: {new Date(comp.soldDate).toLocaleDateString()}</span>
                          </div>
                        </div>
                        <div className="text-right">
                          <p className="font-medium">{formatPrice(comp.price)}</p>
                          <p className="text-sm text-muted-foreground">{comp.pricePerSqm.toLocaleString()} AED/m²</p>
                        </div>
                      </div>
                    ))}
                  </div>
                </CardContent>
              </Card>

              <Card>
                <CardHeader>
                  <CardTitle>Valuation Factors</CardTitle>
                  <CardDescription>Key factors affecting the property value</CardDescription>
                </CardHeader>
                <CardContent>
                  <div className="space-y-3">
                    {result.factors.map((factor, idx) => (
                      <div key={idx} className="flex items-center justify-between p-3 rounded-lg bg-muted/50">
                        <div>
                          <p className="font-medium">{factor.name}</p>
                          <p className="text-sm text-muted-foreground">{factor.description}</p>
                        </div>
                        <Badge variant={factor.impact > 0 ? 'default' : factor.impact < 0 ? 'destructive' : 'secondary'}>
                          {factor.impact > 0 ? '+' : ''}{factor.impact}%
                        </Badge>
                      </div>
                    ))}
                  </div>
                </CardContent>
              </Card>
            </>
          ) : (
            <Card className="flex items-center justify-center h-96">
              <CardContent className="text-center">
                <Calculator className="h-16 w-16 mx-auto text-muted-foreground/50" />
                <p className="mt-4 text-lg font-medium text-muted-foreground">No valuation yet</p>
                <p className="text-sm text-muted-foreground">Fill in the parameters and click "Get Valuation"</p>
              </CardContent>
            </Card>
          )}
        </div>
      </div>
    </div>
  );
}
