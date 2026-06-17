import requests
import xml.etree.ElementTree as ET
import urllib.parse
import time
import json

# Use arXiv API to search for papers
def search_arxiv_api(query, max_results=50, start=0):
    base_url = 'http://export.arxiv.org/api/query'
    params = {
        'search_query': query,
        'start': start,
        'max_results': max_results,
        'sortBy': 'submittedDate',
        'sortOrder': 'descending'
    }
    url = f'{base_url}?{urllib.parse.urlencode(params)}'
    
    try:
        response = requests.get(url, timeout=30)
        return response.text
    except Exception as e:
        print(f'Error: {e}')
        return None

# Search queries
search_queries = [
    'all:"reinforcement learning from human feedback" AND submittedDate:[20250101 TO 20261231]',
    'all:RLHF AND submittedDate:[20250101 TO 20261231]',
    'all:"PPO" AND all:"language model" AND submittedDate:[20250101 TO 20261231]',
    'all:"direct preference optimization" AND submittedDate:[20250101 TO 20261231]',
    'all:"KTO" AND submittedDate:[20250101 TO 20261231]',
    'all:"GRPO" AND submittedDate:[20250101 TO 20261231]',
    'all:"actor-critic" AND all:"language model" AND submittedDate:[20250101 TO 20261231]',
    'all:"RLHF" AND all:alignment AND submittedDate:[20250101 TO 20261231]'
]

all_papers = {}

for query in search_queries:
    print(f'\n=== Searching: {query[:50]}... ===')
    result = search_arxiv_api(query, max_results=30)
    
    if result:
        try:
            root = ET.fromstring(result)
            ns = {'atom': 'http://www.w3.org/2005/Atom', 'arxiv': 'http://arxiv.org/schemas/atom'}
            
            for entry in root.findall('.//atom:entry', ns):
                id_elem = entry.find('atom:id', ns)
                title_elem = entry.find('atom:title', ns)
                summary_elem = entry.find('atom:summary', ns)
                author_elem = entry.findall('atom:author/atom:name', ns)
                published_elem = entry.find('atom:published', ns)
                updated_elem = entry.find('atom:updated', ns)
                link_elem = entry.find('atom:link[@title="pdf"]', ns)
                
                if id_elem is not None:
                    arxiv_id = id_elem.text.split('/')[-1]
                    
                    if arxiv_id not in all_papers:
                        all_papers[arxiv_id] = {
                            'id': arxiv_id,
                            'url': id_elem.text,
                            'pdf_url': link_elem.get('href') if link_elem is not None else '',
                            'title': title_elem.text.strip().replace('\n', ' ') if title_elem is not None else '',
                            'summary': summary_elem.text.strip() if summary_elem is not None else '',
                            'authors': [a.text for a in author_elem] if author_elem else [],
                            'published': published_elem.text[:10] if published_elem is not None else '',
                            'updated': updated_elem.text[:10] if updated_elem is not None else ''
                        }
                        print(f"  Found: {arxiv_id} - {all_papers[arxiv_id]['title'][:60]}...")
            
            time.sleep(3)  # Rate limiting
            
        except Exception as e:
            print(f'  Parse error: {e}')

print(f'\n\n=== Total unique papers found: {len(all_papers)} ===\n')

# Print papers sorted by date
for arxiv_id in sorted(all_papers.keys(), reverse=True):
    paper = all_papers[arxiv_id]
    print(f"arXiv: {paper['id']}")
    print(f"  Title: {paper['title']}")
    print(f"  Authors: {', '.join(paper['authors'][:5])}")
    print(f"  Date: {paper['published']}")
    print(f"  URL: {paper['url']}")
    print(f"  PDF: {paper['pdf_url']}")
    print()