WITH base AS (
    SELECT
        s.s_store_sk,
        s.s_store_name,
        cp.cp_department,
        r.r_reason_sk,
        r.r_reason_desc,
        SUM(cs.cs_net_profit)          AS cat_profit,
        SUM(ss.ss_net_profit)          AS store_profit,
        SUM(ws.ws_net_profit)          AS web_profit,
        SUM(sr.sr_net_loss)            AS return_loss
    FROM catalog_sales      cs
    JOIN catalog_page       cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN time_dim           td ON cs.cs_sold_time_sk   = td.t_time_sk
    JOIN customer           c  ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_address   ca ON cs.cs_bill_addr_sk    = ca.ca_address_sk
    JOIN promotion          p  ON cs.cs_promo_sk        = p.p_promo_sk
    JOIN warehouse          w  ON cs.cs_warehouse_sk    = w.w_warehouse_sk
    JOIN store_sales        ss ON ss.ss_sold_time_sk    = td.t_time_sk
    JOIN store              s  ON ss.ss_store_sk        = s.s_store_sk
    JOIN store_returns      sr ON sr.sr_ticket_number   = ss.ss_ticket_number
    JOIN reason             r  ON sr.sr_reason_sk       = r.r_reason_sk
    JOIN web_sales          ws ON ws.ws_sold_time_sk   = td.t_time_sk
    WHERE cp.cp_department = 'DEPARTMENT'
      AND ca.ca_state = 'TX'
      AND td.t_hour BETWEEN 9 AND 17
    GROUP BY
        s.s_store_sk,
        s.s_store_name,
        cp.cp_department,
        r.r_reason_sk,
        r.r_reason_desc
),
final AS (
    SELECT
        b.s_store_name,
        b.cp_department AS department,
        b.r_reason_desc,
        (b.cat_profit + b.store_profit + b.web_profit - b.return_loss) AS total_profit,
        rc.return_cnt
    FROM base b
    LEFT JOIN LATERAL (
        SELECT COUNT(*) AS return_cnt
        FROM store_returns sr2
        WHERE sr2.sr_store_sk = b.s_store_sk
    ) rc ON TRUE
)
SELECT
    department,
    AVG(total_profit) AS avg_total_profit,
    COUNT(*)         AS store_count
FROM final
GROUP BY department
HAVING AVG(total_profit) > 0
ORDER BY avg_total_profit DESC
LIMIT 100
