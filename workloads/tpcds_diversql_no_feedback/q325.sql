WITH base AS (
    SELECT
        ss.ss_ticket_number,
        ss.ss_net_profit,
        ss.ss_customer_sk,
        sr.sr_ticket_number,
        sr.sr_net_loss,
        sr.sr_customer_sk,
        sr.sr_reason_sk
    FROM store_sales ss
    FULL OUTER JOIN store_returns sr
        ON ss.ss_ticket_number = sr.sr_ticket_number
)
SELECT
    ca.ca_state,
    r.r_reason_desc,
    MIN(substr(c.c_email_address, 1, strpos(c.c_email_address, '@') - 1)) AS sample_email_local,
    SUM(coalesce(base.ss_net_profit, 0)) AS total_sales_profit,
    SUM(coalesce(base.sr_net_loss, 0)) AS total_return_loss,
    COUNT(DISTINCT base.ss_ticket_number) AS sales_txn,
    COUNT(DISTINCT base.sr_ticket_number) AS return_txn
FROM base
LEFT JOIN customer c
    ON c.c_customer_sk = COALESCE(base.ss_customer_sk, base.sr_customer_sk)
LEFT JOIN reason r
    ON r.r_reason_sk = base.sr_reason_sk
LEFT JOIN customer_address ca
    ON ca.ca_address_sk = c.c_current_addr_sk
WHERE
    regexp_like(c.c_email_address, '^.*@example\\.com$')
    AND ca.ca_state LIKE 'C%'
GROUP BY CUBE (ca.ca_state, r.r_reason_desc)
ORDER BY total_sales_profit DESC
LIMIT 100
