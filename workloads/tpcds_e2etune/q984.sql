WITH item_income AS (
    SELECT 
        ib.ib_income_band_sk AS income_band,
        i.i_category AS category,
        COUNT(DISTINCT i.i_item_sk) AS distinct_items,
        AVG(i.i_current_price) AS avg_current_price,
        SUM(i.i_wholesale_cost) AS total_wholesale_cost,
        MIN(i.i_rec_start_date) AS earliest_start_date,
        MAX(i.i_rec_end_date) AS latest_end_date
    FROM 
        item i
    JOIN 
        income_band ib
        ON i.i_current_price BETWEEN ib.ib_lower_bound AND ib.ib_upper_bound
    WHERE 
        i.i_rec_start_date >= DATE '2000-01-01'
        AND i.i_rec_end_date <= DATE '2002-12-31'
        AND i.i_color IN ('Red', 'Blue', 'Green')
    GROUP BY 
        ib.ib_income_band_sk,
        i.i_category
    HAVING 
        COUNT(*) >= 10
)
SELECT 
    income_band,
    category,
    distinct_items,
    avg_current_price,
    total_wholesale_cost,
    earliest_start_date,
    latest_end_date,
    RANK() OVER (PARTITION BY income_band ORDER BY avg_current_price DESC) AS price_rank
FROM 
    item_income
ORDER BY 
    income_band,
    price_rank
