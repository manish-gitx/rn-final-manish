import { supabase } from '../../config/supabase';
import logger from '../../utils/logger';

export const getSongs = async (page: number, limit: number, search?: string) => {
    try {
        logger.info('Fetching songs', { page, limit, search });
        
        const from = (page - 1) * limit;
        const to = from + limit - 1;

        let query = supabase.from('songs').select('*', { count: 'exact' });

        if (search) {
            query = query.ilike('title', `%${search}%`);
            logger.info('Applying search filter', { search });
        }

        query = query.range(from, to);

        const { data, error, count } = await query;

        if (error) {
            logger.error('Error fetching songs', { error, page, limit, search });
            throw error;
        }

        logger.info('Songs fetched successfully', { 
            count: data?.length || 0, 
            total_count: count,
            page, 
            limit 
        });

        return {
            data,
            count,
        };
    } catch (error) {
        logger.error('Error in getSongs service', { error, page, limit, search });
        throw error;
    }
};
