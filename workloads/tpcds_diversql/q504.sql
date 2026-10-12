WITH
    -- Sample a fraction of catalog_sales to keep the query lightweight
    sampled_sales AS (
        SELECT *
        FROM catalog_sales
        TABLESAMPLE BERNOULLI (10)
    ),

    -- Identify stores that are currently open (i.e., not closed)
    open_store_ids AS (
        SELECT s_store_sk
        FROM store
        WHERE s_closed_date_sk IS NULL
    ),
    closed_store_ids AS (
        SELECT s_store_sk
        FROM store
        WHERE s_closed_date_sk IS NOT NULL
    ),
    active_store_ids AS (
        SELECT s_store_sk
        FROM open_store_ids
        EXCEPT
        SELECT s_store_sk
        FROM closed_store_ids
    ),

    -- Sales side data, joining many dimension tables and adding a CASE and a correlated sub‑query
    sales_data AS (
        SELECT
            cs.cs_order_number                                 AS order_id,
            cs.cs_net_profit                                   AS net_amount,
            d_sold.d_year,
            p.p_promo_name                                     AS promo_name,
            ca_bill.ca_state                                   AS state,
            hd_bill.hd_buy_potential                           AS buy_potential,
            'SALE'                                             AS txn_type,
            CASE WHEN cs.cs_net_profit > 0 THEN 'Profit' ELSE 'Loss' END AS profit_flag,
            ROW_NUMBER() OVER (PARTITION BY cs.cs_bill_addr_sk ORDER BY cs.cs_order_number) AS rn,
            (
                SELECT SUM(sr2.sr_return_amt)
                FROM store_returns sr2
                WHERE sr2.sr_addr_sk = ca_bill.ca_address_sk
            )                                                AS total_related_amount
        FROM sampled_sales cs
        JOIN date_dim d_sold
            ON cs.cs_sold_date_sk = d_sold.d_date_sk                              -- 1
        LEFT JOIN promotion p
            ON cs.cs_promo_sk = p.p_promo_sk                                        -- 2
        LEFT JOIN customer_address ca_bill
            ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk                           -- 3
        LEFT JOIN household_demographics hd_bill
            ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk                             -- 4
        -- Additional joins to pull in web info via a second date_dim alias
        JOIN date_dim d_aux
            ON cs.cs_sold_date_sk = d_aux.d_date_sk                                 -- 5
        LEFT JOIN web_page wp
            ON wp.wp_creation_date_sk = d_aux.d_date_sk                               -- 6
        LEFT JOIN web_site ws
            ON ws.web_open_date_sk = d_aux.d_date_sk                                   -- 7
    ),

    -- Returns side data, also heavily joined and containing its own CASE and correlated sub‑query
    returns_data AS (
        SELECT
            sr.sr_ticket_number                                 AS order_id,
            (-sr.sr_net_loss)                                   AS net_amount,
            d_ret.d_year,
            CAST(NULL AS varchar)                               AS promo_name,
            ca_ret.ca_state                                     AS state,
            hd_ret.hd_buy_potential                             AS buy_potential,
            'RETURN'                                            AS txn_type,
            CASE WHEN sr.sr_net_loss > 0 THEN 'Loss' ELSE 'Profit' END AS profit_flag,
            ROW_NUMBER() OVER (PARTITION BY sr.sr_addr_sk ORDER BY sr.sr_ticket_number) AS rn,
            (
                SELECT SUM(cs2.cs_net_paid)
                FROM catalog_sales cs2
                WHERE cs2.cs_bill_addr_sk = ca_ret.ca_address_sk
            )                                                AS total_related_amount
        FROM store_returns sr
        JOIN date_dim d_ret
            ON sr.sr_returned_date_sk = d_ret.d_date_sk                        -- 8
        LEFT JOIN store s
            ON sr.sr_store_sk = s.s_store_sk                                    -- 9
        LEFT JOIN active_store_ids asi
            ON sr.sr_store_sk = asi.s_store_sk                                    -- 10 (uses EXCEPT result)
        LEFT JOIN customer_address ca_ret
            ON sr.sr_addr_sk = ca_ret.ca_address_sk                               -- 11
        LEFT JOIN household_demographics hd_ret
            ON sr.sr_hdemo_sk = hd_ret.hd_demo_sk                                 -- 12
    ),

    -- Union the two streams (sales and returns) with DISTINCT semantics
    union_sales_returns AS (
        SELECT * FROM sales_data
        UNION DISTINCT
        SELECT * FROM returns_data
    )
SELECT
    us.d_year,
    us.state,
    us.profit_flag,
    SUM(us.net_amount)          AS total_net_amount,
    COUNT(*)                    AS txn_count,
    AVG(us.rn)                  AS avg_row_number
FROM union_sales_returns us
GROUP BY
    us.d_year,
    us.state,
    us.profit_flag
ORDER BY total_net_amount DESC
LIMIT 100
