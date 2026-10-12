WITH
    ss_tickets AS (
        SELECT ss_ticket_number AS ticket_number
        FROM store_sales
    ),
    ws_tickets AS (
        SELECT ws_order_number AS ticket_number
        FROM web_sales
    ),
    tickets_excluding AS (
        SELECT ticket_number FROM ss_tickets
        EXCEPT
        SELECT ticket_number FROM ws_tickets
    ),
    cs_items AS (
        SELECT DISTINCT cs_item_sk
        FROM catalog_sales
    ),
    ws_items AS (
        SELECT DISTINCT ws_item_sk
        FROM web_sales
    ),
    intersect_items AS (
        SELECT cs_item_sk
        FROM cs_items
        INTERSECT
        SELECT ws_item_sk
        FROM ws_items
    ),
    aggregated AS (
        SELECT
            d.d_date,
            d.d_year,
            cd.cd_gender,
            we.web_state,
            ib.ib_upper_bound,
            SUM(ss.ss_net_profit) AS total_store_profit,
            SUM(ws.ws_net_profit) AS total_web_profit,
            COUNT(*) FILTER (WHERE ss.ss_ticket_number IN (SELECT ticket_number FROM tickets_excluding)) AS ss_exclusive_ticket_count,
            COUNT(*) FILTER (WHERE cs.cs_item_sk IN (SELECT cs_item_sk FROM intersect_items)) AS intersect_item_sales_count
        FROM
            date_dim d
            LEFT JOIN store_sales ss ON ss.ss_sold_date_sk = d.d_date_sk
            LEFT JOIN store_returns sr ON sr.sr_returned_date_sk = d.d_date_sk AND sr.sr_ticket_number = ss.ss_ticket_number
            LEFT JOIN catalog_sales cs ON cs.cs_sold_date_sk = d.d_date_sk
            FULL OUTER JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
            LEFT JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
            LEFT JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
            LEFT JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
            LEFT JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
            LEFT JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
            LEFT JOIN catalog_returns cr ON cr.cr_returned_date_sk = d.d_date_sk AND cr.cr_order_number = cs.cs_order_number
            LEFT JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
            LEFT JOIN web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk AND wr.wr_order_number = ws.ws_order_number
            LEFT JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
            LEFT JOIN web_site we ON ws.ws_web_site_sk = we.web_site_sk
            LEFT JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
        WHERE
            d.d_year = 2001
            AND cd.cd_gender = 'M'
            AND we.web_state = 'CA'
            AND ib.ib_upper_bound > 50000
            AND ss.ss_item_sk IN (SELECT cs_item_sk FROM catalog_sales WHERE cs_quantity > 5)
            AND EXISTS (
                SELECT 1 FROM catalog_returns cr2
                WHERE cr2.cr_order_number = cs.cs_order_number
                  AND cr2.cr_return_amount > 100
            )
        GROUP BY
            d.d_date,
            d.d_year,
            cd.cd_gender,
            we.web_state,
            ib.ib_upper_bound
    )
SELECT
    d_date,
    cd_gender,
    web_state,
    ib_upper_bound,
    total_store_profit,
    total_web_profit,
    CASE
        WHEN total_store_profit > total_web_profit THEN 'Store Better'
        ELSE 'Web Better'
    END AS profit_winner,
    RANK() OVER (PARTITION BY d_year ORDER BY total_store_profit DESC) AS profit_rank_by_year,
    ss_exclusive_ticket_count,
    intersect_item_sales_count
FROM aggregated
ORDER BY total_store_profit DESC, profit_rank_by_year
LIMIT 100
