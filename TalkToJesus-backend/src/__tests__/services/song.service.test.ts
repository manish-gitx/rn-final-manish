jest.mock('../../config/supabase');
jest.mock('../../utils/logger', () => ({
  __esModule: true,
  default: { info: jest.fn(), warn: jest.fn(), error: jest.fn() },
}));

import { supabase } from '../../config/supabase';
import { getSongs } from '../../api/services/song.service';

const mockSupabase = supabase as any;

describe('Song Service', () => {
  beforeEach(() => jest.clearAllMocks());

  it('should return paginated songs with correct offset', async () => {
    const mockSongs = [
      { id: '1', title: 'Song 1' },
      { id: '2', title: 'Song 2' },
    ];

    const chain: any = {};
    chain.select = jest.fn().mockReturnValue(chain);
    chain.ilike = jest.fn().mockReturnValue(chain);
    chain.range = jest.fn().mockResolvedValue({ data: mockSongs, error: null, count: 10 });
    mockSupabase.from = jest.fn().mockReturnValue(chain);

    const result = await getSongs(2, 5);

    // Page 2, limit 5 → from=5, to=9
    expect(chain.range).toHaveBeenCalledWith(5, 9);
    expect(result.data).toEqual(mockSongs);
    expect(result.count).toBe(10);
  });

  it('should apply search filter when provided', async () => {
    const chain: any = {};
    chain.select = jest.fn().mockReturnValue(chain);
    chain.ilike = jest.fn().mockReturnValue(chain);
    chain.range = jest.fn().mockResolvedValue({ data: [], error: null, count: 0 });
    mockSupabase.from = jest.fn().mockReturnValue(chain);

    await getSongs(1, 10, 'hallelujah');

    expect(chain.ilike).toHaveBeenCalledWith('title', '%hallelujah%');
  });

  it('should not apply search filter when not provided', async () => {
    const chain: any = {};
    chain.select = jest.fn().mockReturnValue(chain);
    chain.ilike = jest.fn().mockReturnValue(chain);
    chain.range = jest.fn().mockResolvedValue({ data: [], error: null, count: 0 });
    mockSupabase.from = jest.fn().mockReturnValue(chain);

    await getSongs(1, 10);

    expect(chain.ilike).not.toHaveBeenCalled();
  });

  it('should throw on database error', async () => {
    const chain: any = {};
    chain.select = jest.fn().mockReturnValue(chain);
    chain.range = jest.fn().mockResolvedValue({ data: null, error: { message: 'DB error' }, count: null });
    mockSupabase.from = jest.fn().mockReturnValue(chain);

    await expect(getSongs(1, 10)).rejects.toEqual({ message: 'DB error' });
  });

  it('should calculate correct offset for first page', async () => {
    const chain: any = {};
    chain.select = jest.fn().mockReturnValue(chain);
    chain.range = jest.fn().mockResolvedValue({ data: [], error: null, count: 0 });
    mockSupabase.from = jest.fn().mockReturnValue(chain);

    await getSongs(1, 20);

    // Page 1, limit 20 → from=0, to=19
    expect(chain.range).toHaveBeenCalledWith(0, 19);
  });
});
