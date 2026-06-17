import { useState } from "react";
import { z } from "zod";
import { toast } from "sonner";
import { Sparkles, Check } from "lucide-react";
import { Dialog, DialogContent, DialogDescription, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Checkbox } from "@/components/ui/checkbox";
import { cn } from "@/lib/utils";

const COUNTRIES = ["UAE", "Saudi Arabia", "Qatar", "Bahrain", "Kuwait", "Oman"];
const BUDGETS = ["Under $100k", "$100k – $500k", "$500k – $2M", "$2M – $10M", "$10M+"];

const schema = z.object({
  name: z.string().trim().min(2, "Name is too short").max(80),
  email: z.string().trim().email("Enter a valid email").max(255),
  phone: z.string().trim().min(6, "Enter a valid phone number").max(30),
  budget: z.string().min(1, "Pick a budget range"),
  countries: z.array(z.string()).min(1, "Pick at least one country"),
});

interface Props {
  open: boolean;
  onOpenChange: (open: boolean) => void;
}

export function WaitlistModal({ open, onOpenChange }: Props) {
  const [form, setForm] = useState({ name: "", email: "", phone: "", budget: "" });
  const [countries, setCountries] = useState<string[]>([]);
  const [loading, setLoading] = useState(false);
  const [done, setDone] = useState(false);

  function toggleCountry(c: string) {
    setCountries((prev) => (prev.includes(c) ? prev.filter((x) => x !== c) : [...prev, c]));
  }

  async function onSubmit(e: React.FormEvent) {
    e.preventDefault();
    const parsed = schema.safeParse({ ...form, countries });
    if (!parsed.success) {
      toast.error(parsed.error.issues[0]?.message ?? "Please complete the form");
      return;
    }
    setLoading(true);
    try {
      const list = JSON.parse(localStorage.getItem("gulflands-waitlist") || "[]");
      list.push({ ...parsed.data, at: new Date().toISOString(), source: "modal" });
      localStorage.setItem("gulflands-waitlist", JSON.stringify(list));
      // TODO: POST to /v1/waitlist when API is available
      await new Promise((r) => setTimeout(r, 500));
      setDone(true);
      toast.success("You're on the list!");
    } finally {
      setLoading(false);
    }
  }

  function handleOpenChange(o: boolean) {
    onOpenChange(o);
    if (!o) {
      setTimeout(() => {
        setDone(false);
        setForm({ name: "", email: "", phone: "", budget: "" });
        setCountries([]);
      }, 300);
    }
  }

  return (
    <Dialog open={open} onOpenChange={handleOpenChange}>
      <DialogContent className="max-w-lg p-0 overflow-hidden gap-0">
        <div className="bg-gradient-to-br from-navy via-navy to-navy/85 px-6 pt-6 pb-8 text-white">
          <span className="inline-flex items-center gap-1.5 rounded-full bg-gold/20 border border-gold/30 px-3 py-1 text-xs font-semibold text-gold">
            <Sparkles className="h-3 w-3" /> Early Access
          </span>
          <DialogHeader className="mt-3 space-y-1.5">
            <DialogTitle className="font-display text-2xl font-bold text-white text-left">
              {done ? "You're on the list." : "Get early access to Gulf Lands"}
            </DialogTitle>
            <DialogDescription className="text-white/75 text-left">
              {done
                ? "We'll reach out within 48 hours with curated plots that match your criteria."
                : "Tell us a bit about your investment goals and we'll match you with relevant plots."}
            </DialogDescription>
          </DialogHeader>
        </div>

        {done ? (
          <div className="px-6 py-10 text-center">
            <div className="mx-auto h-16 w-16 rounded-full bg-gold/20 flex items-center justify-center">
              <Check className="h-8 w-8 text-gold" strokeWidth={3} />
            </div>
            <p className="mt-6 text-sm text-muted-foreground">
              Check your inbox for confirmation. Pro tip: add us to your contacts so we don't land in spam.
            </p>
            <Button
              className="mt-6 bg-navy text-navy-foreground hover:bg-navy/90"
              onClick={() => handleOpenChange(false)}
            >
              Close
            </Button>
          </div>
        ) : (
          <form onSubmit={onSubmit} className="px-6 py-6 space-y-4">
            <div className="grid grid-cols-2 gap-4">
              <div className="col-span-2 space-y-1.5">
                <Label htmlFor="wl-name">Full name</Label>
                <Input
                  id="wl-name"
                  value={form.name}
                  onChange={(e) => setForm({ ...form, name: e.target.value })}
                  placeholder="Khalid Al-Mansoori"
                  required
                  maxLength={80}
                />
              </div>
              <div className="col-span-2 sm:col-span-1 space-y-1.5">
                <Label htmlFor="wl-email">Email</Label>
                <Input
                  id="wl-email"
                  type="email"
                  value={form.email}
                  onChange={(e) => setForm({ ...form, email: e.target.value })}
                  placeholder="you@company.com"
                  required
                  maxLength={255}
                />
              </div>
              <div className="col-span-2 sm:col-span-1 space-y-1.5">
                <Label htmlFor="wl-phone">Phone</Label>
                <Input
                  id="wl-phone"
                  type="tel"
                  value={form.phone}
                  onChange={(e) => setForm({ ...form, phone: e.target.value })}
                  placeholder="+971 50 000 0000"
                  required
                  maxLength={30}
                />
              </div>
            </div>

            <div className="space-y-1.5">
              <Label>Investment budget</Label>
              <Select value={form.budget} onValueChange={(v) => setForm({ ...form, budget: v })}>
                <SelectTrigger>
                  <SelectValue placeholder="Select a budget range" />
                </SelectTrigger>
                <SelectContent>
                  {BUDGETS.map((b) => (
                    <SelectItem key={b} value={b}>{b}</SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>

            <div className="space-y-2">
              <Label>Preferred countries</Label>
              <div className="grid grid-cols-2 sm:grid-cols-3 gap-2">
                {COUNTRIES.map((c) => {
                  const checked = countries.includes(c);
                  return (
                    <label
                      key={c}
                      className={cn(
                        "flex items-center gap-2 rounded-lg border px-3 py-2.5 text-sm cursor-pointer transition",
                        checked ? "border-gold bg-gold/10 text-foreground" : "border-border hover:bg-accent",
                      )}
                    >
                      <Checkbox checked={checked} onCheckedChange={() => toggleCountry(c)} />
                      <span className="font-medium">{c}</span>
                    </label>
                  );
                })}
              </div>
            </div>

            <Button
              type="submit"
              disabled={loading}
              className="w-full h-12 bg-gold text-gold-foreground hover:bg-gold/90 font-semibold"
            >
              {loading ? "Submitting…" : "Join the waitlist"}
            </Button>
            <p className="text-[11px] text-muted-foreground text-center">
              By submitting, you agree to our Terms and Privacy Policy.
            </p>
          </form>
        )}
      </DialogContent>
    </Dialog>
  );
}
