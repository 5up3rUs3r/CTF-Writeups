# niteCTF 2025 - Writeups

**Author:** [5up3rUs3r](https://github.com/5up3rUs3r)  
**Date:** December 12–14, 2025  
**Total Points:** 150  
**CTFtime Rating Points:** 0.946  
**Final Placement:** 333rd

## Event Info

> niteCTF is a jeopardy-style CTF organized by **Cryptonite MIT** for students interested in Cybersecurity. Challenges span binary exploitation, forensics, hardware security, cryptography, web exploitation, AI, Web3, and more.  
> **CTFtime:** https://ctftime.org/event/2851  
> **Official Repo:** https://github.com/Cryptonite-MIT/niteCTF-2025

## Challenges Solved

| Challenge                                                    | Category         | Vulnerability                                                                         | Flag                                                    |
| ------------------------------------------------------------ | ---------------- | ------------------------------------------------------------------------------------- | ------------------------------------------------------- |
| [Single Sign Off](./Single_Sign_Off/README.md)               | Web Exploitation | CVE-2025-0167 · curl .netrc credential leak via open redirect + SSRF                  | `nite{r3dir3ct_l3ak_r3p3at}`                            |
| [Graph Grief](./Graph_Grief/README.md)                       | Web Exploitation | OOB XXE → SSRF to bypass IP whitelist on internal GraphQL endpoint                    | `nite{Th3_Qu4ntum_Ent1ty_H4s_B33n_Summ0n3d}`            |
| [Database Reincursion](./Database_Reincursion/README.md)     | Web Exploitation | 3-stage SQL injection with filter bypass and UNION-based exfil                        | `nite{neVeR_9Onn4_57OP_WonDER1N9_1f_175_5ql_oR_5EKWeL}` |
| [Double Trouble](./Double_Trouble/README.md)                 | Web Exploitation | HTTP Request Smuggling · HAProxy CVE-2021-40346 integer overflow                      | `nite{h11p_1_1_must_d1e}`                               |
| [Car Seat HEADrest](./Car_Seat_HEADrest/README.md)           | Web Exploitation | XS-Leak via CVE-2025-4664-style Link header referrer policy override                  | `nite{ihaventlookedatthesunforsooolooong}`              |
| [Just Another Notes App](./Just_Another_Notes_App/README.md) | Web Exploitation | 431 Request Header Fields Too Large → admin token leak via Gunicorn header size limit | `nite{r3qu3575_d0n7_n33d_70_4lw4y5_c0mpl373}`           |

## Quick Links

- [My GitHub](https://github.com/5up3rUs3r)
- [CTF Writeups Repo](https://github.com/5up3rUs3r/CTF-Writeups)

## About

These writeups document my solutions for niteCTF 2025. All challenges were in the Web Exploitation category, covering a wide range of modern attack techniques: CVE exploitation, request smuggling, XS-Leaks, multi-stage SQL injection, OOB XXE, and browser-based side channels. This CTF had a strong emphasis on real-world scenarios and multi-service vulnerability chaining.
