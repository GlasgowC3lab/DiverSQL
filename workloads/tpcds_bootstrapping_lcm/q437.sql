WITH returns_agg AS (
    SELECT
        d_ret.d_current_year,
        d_ret.d_current_month,
        i.i_product_name,
        i.i_brand,
        p.p_promo_name,
        s.s_store_name,
        SUM(wr.wr_return_amt) AS total_return_amount,
        SUM(wr.wr_net_loss) AS total_net_loss,
        COUNT(*) AS return_count,
        SUM(CASE WHEN wr.wr_return_quantity > 1 THEN 1 ELSE 0 END) AS multi_item_returns,
        MIN(d_start.d_date) AS promo_start_date,
        MAX(d_end.d_date) AS promo_end_date,
        SUM(p.p_cost) AS total_promo_cost
    FROM web_returns wr
    JOIN date_dim d_ret
        ON wr.wr_returned_date_sk = d_ret.d_date_sk
    JOIN item i
        ON wr.wr_item_sk = i.i_item_sk
    JOIN promotion p
        ON p.p_item_sk = i.i_item_sk
    JOIN date_dim d_start
        ON p.p_start_date_sk = d_start.d_date_sk
    JOIN date_dim d_end
        ON p.p_end_date_sk = d_end.d_date_sk
    JOIN store s
        ON s.s_closed_date_sk = d_ret.d_date_sk
    WHERE d_ret.d_year = 2022
      AND s.s_state = 'CA'
      AND p.p_cost > 500
    GROUP BY
        d_ret.d_current_year,
        d_ret.d_current_month,
        i.i_product_name,
        i.i_brand,
        p.p_promo_name,
        s.s_store_name
    HAVING SUM(wr.wr_return_amt) > 1000
)
SELECT
    ra.d_current_year,
    ra.d_current_month,
    ra.i_product_name,
    ra.i_brand,
    ra.p_promo_name,
    ra.s_store_name,
    ra.total_return_amount,
    ra.total_net_loss,
    ra.return_count,
    ra.multi_item_returns,
    ra.promo_start_date,
    ra.promo_end_date,
    ra.total_promo_cost,
    ROW_NUMBER() OVER (PARTITION BY ra.i_product_name ORDER BY ra.total_return_amount DESC) AS product_return_rank
FROM returns_agg ra
ORDER BY ra.total_return_amount DESC
LIMIT 100
