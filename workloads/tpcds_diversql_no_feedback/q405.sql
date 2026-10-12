WITH agg1 AS (
    SELECT
        store.s_store_id,
        item.i_item_id,
        time_dim.t_hour,
        household_demographics.hd_buy_potential,
        SUM(store_sales.ss_net_paid) AS total_net_paid,
        SUM(COALESCE(catalog_returns.cr_return_amount, 0)) AS total_return_amount,
        SUM(COALESCE(web_returns.wr_return_amt, 0)) AS total_web_return_amount,
        COUNT(DISTINCT store_sales.ss_ticket_number) AS distinct_tickets,
        AVG(income_band.ib_lower_bound) AS avg_income_lower
    FROM store_sales
    JOIN time_dim
        ON store_sales.ss_sold_time_sk = time_dim.t_time_sk
    JOIN item
        ON store_sales.ss_item_sk = item.i_item_sk
    JOIN customer
        ON store_sales.ss_customer_sk = customer.c_customer_sk
    JOIN customer_demographics
        ON store_sales.ss_cdemo_sk = customer_demographics.cd_demo_sk
    JOIN household_demographics
        ON store_sales.ss_hdemo_sk = household_demographics.hd_demo_sk
    JOIN store
        ON store_sales.ss_store_sk = store.s_store_sk
    JOIN promotion
        ON store_sales.ss_promo_sk = promotion.p_promo_sk
    JOIN inventory
        ON inventory.inv_item_sk = item.i_item_sk
    JOIN income_band
        ON household_demographics.hd_income_band_sk = income_band.ib_income_band_sk
    LEFT JOIN catalog_returns
        ON catalog_returns.cr_item_sk = item.i_item_sk
        AND catalog_returns.cr_returned_time_sk = time_dim.t_time_sk
    RIGHT JOIN web_returns
        ON web_returns.wr_item_sk = item.i_item_sk
        AND web_returns.wr_returned_time_sk = time_dim.t_time_sk
    WHERE item.i_brand = 'Brand#45'
      AND store.s_state = 'CA'
      AND time_dim.t_hour BETWEEN 9 AND 17
    GROUP BY store.s_store_id, item.i_item_id, time_dim.t_hour, household_demographics.hd_buy_potential
    HAVING SUM(store_sales.ss_net_paid) > 10000
),
agg2 AS (
    SELECT
        store.s_store_id,
        item.i_item_id,
        time_dim.t_hour,
        household_demographics.hd_buy_potential,
        SUM(store_sales.ss_net_paid) AS total_net_paid,
        SUM(COALESCE(catalog_returns.cr_return_amount, 0)) AS total_return_amount,
        SUM(COALESCE(web_returns.wr_return_amt, 0)) AS total_web_return_amount,
        COUNT(DISTINCT store_sales.ss_ticket_number) AS distinct_tickets,
        AVG(income_band.ib_lower_bound) AS avg_income_lower
    FROM store_sales
    JOIN time_dim
        ON store_sales.ss_sold_time_sk = time_dim.t_time_sk
    JOIN item
        ON store_sales.ss_item_sk = item.i_item_sk
    JOIN customer
        ON store_sales.ss_customer_sk = customer.c_customer_sk
    JOIN customer_demographics
        ON store_sales.ss_cdemo_sk = customer_demographics.cd_demo_sk
    JOIN household_demographics
        ON store_sales.ss_hdemo_sk = household_demographics.hd_demo_sk
    JOIN store
        ON store_sales.ss_store_sk = store.s_store_sk
    JOIN promotion
        ON store_sales.ss_promo_sk = promotion.p_promo_sk
    JOIN inventory
        ON inventory.inv_item_sk = item.i_item_sk
    JOIN income_band
        ON household_demographics.hd_income_band_sk = income_band.ib_income_band_sk
    LEFT JOIN catalog_returns
        ON catalog_returns.cr_item_sk = item.i_item_sk
        AND catalog_returns.cr_returned_time_sk = time_dim.t_time_sk
    RIGHT JOIN web_returns
        ON web_returns.wr_item_sk = item.i_item_sk
        AND web_returns.wr_returned_time_sk = time_dim.t_time_sk
    WHERE item.i_brand = 'Brand#12'
      AND store.s_state = 'TX'
      AND time_dim.t_hour BETWEEN 18 AND 23
    GROUP BY store.s_store_id, item.i_item_id, time_dim.t_hour, household_demographics.hd_buy_potential
    HAVING SUM(store_sales.ss_net_paid) > 5000
)
SELECT *
FROM (
    SELECT * FROM agg1
    UNION
    SELECT * FROM agg2
) AS combined
ORDER BY total_net_paid DESC
LIMIT 100
