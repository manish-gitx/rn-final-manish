import { supabase } from '../../config/supabase';
import logger from '../../utils/logger';

/**
 * Get plans filtered by environment
 * Returns plans where is_prod matches the current NODE_ENV
 */
export const getPlans = async () => {
    try {
        const isProduction = process.env.NODE_ENV === 'production';
        const isProdValue = isProduction;
        
        logger.info('Fetching plans', { 
            environment: process.env.NODE_ENV, 
            isProduction,
            filtering_by_is_prod: isProdValue 
        });
        
        // Filter plans based on current environment
        const { data, error } = await supabase
            .from('plans')
            .select('*')
            .eq('is_prod', isProdValue);

        if (error) {
            logger.error('Error fetching plans', { error });
            throw error;
        }
        
        logger.info('Plans fetched successfully', { 
            count: data?.length || 0,
            environment: process.env.NODE_ENV,
            is_prod_filter: isProdValue
        });
        
        return data;
    } catch (error) {
        logger.error('Error in getPlans service', { error });
        throw error;
    }
};
