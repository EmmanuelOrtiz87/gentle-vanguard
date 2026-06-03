import { readFileSync, writeFileSync, existsSync } from "fs";
import { join } from "path";

const DATA_PATH = join(__dirname, "..", "data", "marketplace.json");

interface SkillListing {
  id: string;
  name: string;
  description: string;
  author: string;
  version: string;
  downloads: number;
  rating: number;
  reviews: Review[];
  tags: string[];
  createdAt: string;
  updatedAt: string;
}

interface Review {
  id: string;
  user: string;
  rating: number;
  comment: string;
  createdAt: string;
}

function loadMarketplace(): SkillListing[] {
  if (!existsSync(DATA_PATH)) {
    return [];
  }
  try {
    const data = readFileSync(DATA_PATH, "utf-8");
    return JSON.parse(data);
  } catch {
    return [];
  }
}

function saveMarketplace(listings: SkillListing[]) {
  writeFileSync(DATA_PATH, JSON.stringify(listings, null, 2));
}

export function getListings(): SkillListing[] {
  return loadMarketplace();
}

export function getListing(id: string): SkillListing | undefined {
  return loadMarketplace().find((l) => l.id === id);
}

export function createListing(listing: Omit<SkillListing, "id" | "createdAt" | "updatedAt" | "downloads" | "rating" | "reviews">): SkillListing {
  const listings = loadMarketplace();
  const newListing: SkillListing = {
    ...listing,
    id: `listing-${Date.now()}`,
    downloads: 0,
    rating: 0,
    reviews: [],
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString(),
  };
  listings.push(newListing);
  saveMarketplace(listings);
  return newListing;
}

export function addReview(listingId: string, review: Omit<Review, "id" | "createdAt">): Review {
  const listings = loadMarketplace();
  const listing = listings.find((l) => l.id === listingId);
  if (!listing) {
    throw new Error("Listing not found");
  }
  
  const newReview: Review = {
    ...review,
    id: `review-${Date.now()}`,
    createdAt: new Date().toISOString(),
  };
  
  listing.reviews.push(newReview);
  listing.rating = listing.reviews.reduce((acc, r) => acc + r.rating, 0) / listing.reviews.length;
  listing.updatedAt = new Date().toISOString();
  
  saveMarketplace(listings);
  return newReview;
}

export function incrementDownloads(listingId: string) {
  const listings = loadMarketplace();
  const listing = listings.find((l) => l.id === listingId);
  if (listing) {
    listing.downloads++;
    listing.updatedAt = new Date().toISOString();
    saveMarketplace(listings);
  }
}
