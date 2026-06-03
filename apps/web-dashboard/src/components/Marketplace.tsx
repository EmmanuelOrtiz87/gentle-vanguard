import { useEffect, useState } from 'react';
import { Star, Download, Tag, User, Plus } from 'lucide-react';

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
}

interface Review {
  id: string;
  user: string;
  rating: number;
  comment: string;
}

export function Marketplace() {
  const [listings, setListings] = useState<SkillListing[]>([]);
  const [selectedListing, setSelectedListing] = useState<SkillListing | null>(null);
  const [filter, setFilter] = useState('');

  useEffect(() => {
    // Load marketplace data
    const mockListings: SkillListing[] = [
      {
        id: '1',
        name: 'react-hooks-skill',
        description: 'Advanced React hooks patterns and best practices',
        author: 'dev-expert',
        version: '1.2.0',
        downloads: 1234,
        rating: 4.8,
        reviews: [
          { id: 'r1', user: 'user1', rating: 5, comment: 'Excellent skill!' },
        ],
        tags: ['react', 'frontend', 'hooks'],
      },
      {
        id: '2',
        name: 'api-design-skill',
        description: 'RESTful API design patterns and OpenAPI specs',
        author: 'api-guru',
        version: '2.0.1',
        downloads: 856,
        rating: 4.5,
        reviews: [],
        tags: ['api', 'backend', 'rest'],
      },
    ];
    setListings(mockListings);
  }, []);

  const filteredListings = listings.filter((l) =>
    l.name.toLowerCase().includes(filter.toLowerCase()) ||
    l.tags.some((t) => t.toLowerCase().includes(filter.toLowerCase()))
  );

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <h2 className="text-2xl font-bold text-gray-900 dark:text-white">Skill Marketplace</h2>
        <button className="flex items-center gap-2 px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700">
          <Plus className="w-4 h-4" />
          Publish Skill
        </button>
      </div>

      {/* Search */}
      <div className="card">
        <input
          type="text"
          placeholder="Search skills..."
          value={filter}
          onChange={(e) => setFilter(e.target.value)}
          className="w-full px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-800 text-gray-900 dark:text-white"
        />
      </div>

      {/* Listings Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        {filteredListings.map((listing) => (
          <div
            key={listing.id}
            className="card cursor-pointer hover:shadow-lg transition-shadow"
            onClick={() => setSelectedListing(listing)}
          >
            <div className="flex items-start justify-between mb-2">
              <h3 className="text-lg font-semibold text-gray-900 dark:text-white">{listing.name}</h3>
              <span className="text-xs text-gray-500">v{listing.version}</span>
            </div>
            <p className="text-sm text-gray-600 dark:text-gray-400 mb-4">{listing.description}</p>
            
            <div className="flex items-center gap-4 text-sm text-gray-500 mb-3">
              <span className="flex items-center gap-1">
                <Download className="w-4 h-4" />
                {listing.downloads}
              </span>
              <span className="flex items-center gap-1">
                <Star className="w-4 h-4 text-yellow-500" />
                {listing.rating.toFixed(1)}
              </span>
            </div>

            <div className="flex items-center gap-2 text-sm text-gray-500 mb-3">
              <User className="w-4 h-4" />
              {listing.author}
            </div>

            <div className="flex flex-wrap gap-2">
              {listing.tags.map((tag) => (
                <span key={tag} className="flex items-center gap-1 px-2 py-1 bg-gray-100 dark:bg-gray-700 rounded text-xs">
                  <Tag className="w-3 h-3" />
                  {tag}
                </span>
              ))}
            </div>
          </div>
        ))}
      </div>

      {/* Detail Modal */}
      {selectedListing && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center p-4 z-50">
          <div className="bg-white dark:bg-gray-800 rounded-lg max-w-2xl w-full max-h-[80vh] overflow-y-auto p-6">
            <div className="flex items-start justify-between mb-4">
              <div>
                <h3 className="text-2xl font-bold text-gray-900 dark:text-white">{selectedListing.name}</h3>
                <p className="text-gray-600 dark:text-gray-400">{selectedListing.description}</p>
              </div>
              <button
                onClick={() => setSelectedListing(null)}
                className="text-gray-500 hover:text-gray-700"
              >
                ✕
              </button>
            </div>

            <div className="space-y-4">
              <div className="flex items-center gap-6 text-sm">
                <span className="flex items-center gap-1">
                  <Download className="w-4 h-4" />
                  {selectedListing.downloads} downloads
                </span>
                <span className="flex items-center gap-1">
                  <Star className="w-4 h-4 text-yellow-500" />
                  {selectedListing.rating.toFixed(1)} ({selectedListing.reviews.length} reviews)
                </span>
              </div>

              <div>
                <h4 className="font-semibold mb-2">Reviews</h4>
                {selectedListing.reviews.length === 0 ? (
                  <p className="text-gray-500 text-sm">No reviews yet</p>
                ) : (
                  <div className="space-y-2">
                    {selectedListing.reviews.map((review) => (
                      <div key={review.id} className="border-b border-gray-200 dark:border-gray-700 pb-2">
                        <div className="flex items-center gap-2">
                          <span className="font-medium">{review.user}</span>
                          <span className="flex items-center text-yellow-500">
                            <Star className="w-4 h-4" />
                            {review.rating}
                          </span>
                        </div>
                        <p className="text-sm text-gray-600 dark:text-gray-400">{review.comment}</p>
                      </div>
                    ))}
                  </div>
                )}
              </div>

              <button className="w-full py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700">
                Install Skill
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

export default Marketplace;
