WITH 
    sales_union AS (
        SELECT 
            ss.ss_sold_date_sk AS sold_date_sk,
            ss.ss_item_sk AS item_sk,
            ss.ss_quantity AS quantity,
            ss.ss_net_paid AS net_paid,
            ss.ss_net_profit AS net_profit,
            'store' AS channel,
            ss.ss_promo_sk AS promo_sk,
            ss.ss_store_sk AS store_sk,
            CAST(NULL AS integer) AS warehouse_sk,
            CAST(NULL AS integer) AS catalog_page_sk,
            ss.ss_ticket_number AS ticket_number
        FROM store_sales ss
        UNION ALL
        SELECT 
            cs.cs_sold_date_sk AS sold_date_sk,
            cs.cs_item_sk AS item_sk,
            cs.cs_quantity AS quantity,
            cs.cs_net_paid AS net_paid,
            cs.cs_net_profit AS net_profit,
            'catalog' AS channel,
            cs.cs_promo_sk AS promo_sk,
            CAST(NULL AS integer) AS store_sk,
            cs.cs_warehouse_sk AS warehouse_sk,
            cs.cs_catalog_page_sk AS catalog_page_sk,
            cs.cs_order_number AS ticket_number
        FROM catalog_sales cs
        UNION ALL
        SELECT 
            ws.ws_sold_date_sk AS sold_date_sk,
            ws.ws_item_sk AS item_sk,
            ws.ws_quantity AS quantity,
            ws.ws_net_paid AS net_paid,
            ws.ws_net_profit AS net_profit,
            'web' AS channel,
            ws.ws_promo_sk AS promo_sk,
            CAST(NULL AS integer) AS store_sk,
            ws.ws_warehouse_sk AS warehouse_sk,
            CAST(NULL AS integer) AS catalog_page_sk,
            ws.ws_order_number AS ticket_number
        FROM web_sales ws
    ),
    latest_price AS (
        SELECT i.i_item_sk,
               i.i_current_price,
               i.i_item_desc
        FROM item i
        WHERE i.i_rec_end_date IS NULL OR i.i_rec_end_date = (
            SELECT MAX(i2.i_rec_end_date)
            FROM item i2
            WHERE i2.i_item_sk = i.i_item_sk
        )
    ),
    yearly_sales AS (
        SELECT 
            su.item_sk,
            d.d_year,
            SUM(su.net_profit) AS total_profit,
            SUM(su.net_paid) AS total_revenue,
            SUM(su.quantity) AS total_quantity,
            MIN(d.d_date) AS first_sale_date,
            MAX(d.d_date) AS last_sale_date,
            MIN(su.channel) AS any_channel
        FROM sales_union su
        JOIN date_dim d ON su.sold_date_sk = d.d_date_sk
        WHERE d.d_year BETWEEN 1999 AND 2001
        GROUP BY su.item_sk, d.d_year
    ),
    profit_rank AS (
        SELECT 
            y.item_sk,
            y.d_year AS year,
            y.total_profit,
            y.total_revenue,
            y.total_quantity,
            lp.i_current_price,
            lp.i_item_desc,
            ROW_NUMBER() OVER (PARTITION BY y.d_year ORDER BY y.total_profit DESC) AS profit_rank,
            COALESCE(p.p_discount_active, 'N') AS promo_active_flag
        FROM yearly_sales y
        LEFT JOIN latest_price lp ON y.item_sk = lp.i_item_sk
        LEFT JOIN promotion p ON p.p_item_sk = y.item_sk
    ),
    items_with_returns AS (
        SELECT DISTINCT sr_item_sk AS item_sk FROM store_returns
        UNION
        SELECT DISTINCT cr_item_sk AS item_sk FROM catalog_returns
        UNION
        SELECT DISTINCT wr_item_sk AS item_sk FROM web_returns
    ),
    filtered_items AS (
        SELECT pr.*
        FROM profit_rank pr
        LEFT JOIN items_with_returns ir ON pr.item_sk = ir.item_sk
        WHERE pr.profit_rank <= 10 AND ir.item_sk IS NOT NULL
    )
SELECT 
    fi.year,
    fi.item_sk,
    fi.i_item_desc,
    fi.total_quantity,
    fi.total_revenue,
    fi.total_profit,
    ROUND(fi.total_profit / NULLIF(fi.total_revenue, 0) * 100, 2) AS profit_margin_pct,
    CONCAT('Rank ', CAST(fi.profit_rank AS VARCHAR), ' in ', CAST(fi.year AS VARCHAR)) AS rank_label,
    CASE 
        WHEN fi.promo_active_flag = 'Y' THEN 'Promoted'
        ELSE 'Not Promoted'
    END AS promotion_status,
    COALESCE(fi.i_current_price, 0) AS latest_price,
    CASE 
        WHEN COALESCE(fi.i_item_desc, '') LIKE '%MEDIUM%' THEN 'Medium Size'
        ELSE 'Other Size'
    END AS size_category
FROM filtered_items fi
ORDER BY fi.year, fi.profit_rank
