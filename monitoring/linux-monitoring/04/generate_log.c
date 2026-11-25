#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <stdbool.h>
#include <string.h>

// # Коды HTTP ответов и их значения:
// # 200 - OK (успешный запрос)
// # 201 - Created (ресурс создан)
// # 400 - Bad Request (неверный синтаксис запроса)
// # 401 - Unauthorized (требуется аутентификация)
// # 403 - Forbidden (доступ запрещен)
// # 404 - Not Found (ресурс не найден)
// # 500 - Internal Server Error (ошибка сервера)
// # 501 - Not Implemented (метод не поддерживается)
// # 502 - Bad Gateway (ошибка шлюза)
// # 503 - Service Unavailable (сервис недоступен)

void GenerateLog(char *LogString, FILE* logfile);
void GetRandomIp(char *RemoteAddr);
int IsAddrVarlid(int Octet1, int Octet2, int Octet3, int Octet4);
void TimeLocal(char *Time, int trigger); 
char *GetTimeZone(void);
void GetRequestMethod(char **RequestMethod);
char* GetHttpVersion(void);
typedef struct {
    char *url; 
    char *description;
} RequestUrl_t;

RequestUrl_t GetRequestUrl(char *RequestMethod);
int GetStatusCodeForRequest(char* method, char* url);
int GenerateBodyBytesSent(char* method, char* url, int status_code);
char* GenerateHttpReferer(const char* url);
char* GenerateUserAgent(void);

int main() {
    srand(time(0));
    char *filename[5] = {"access0.log", "access1.log", "access2.log", "access3.log", "access4.log"};
    for (int i = 0; i < 5; i ++) {

        FILE* logfile = fopen(filename[i], "w");
        if (logfile == NULL) {
            perror("Ошибка открытия файла");
            return 1;
        }
        char LogString[1000];
        GenerateLog(LogString, logfile);

        fclose(logfile);
    }   

    return 0;
} 


void GenerateLog(char *LogString, FILE* logfile) {
    char RemoteAddr[19];
    char Time[20];
    char *RequestMethod;
    char *LocalUTC = GetTimeZone();
    
    
    int LogLength = rand() % 900 + 100;
    for(int i = 0; i < LogLength; i++) {
        GetRandomIp(RemoteAddr);
        GetRequestMethod(&RequestMethod);
        TimeLocal (Time, i);
        RequestUrl_t RequestUrl = GetRequestUrl(RequestMethod);
        char* HttpVersion = GetHttpVersion();
        int StatusCode = GetStatusCodeForRequest(RequestMethod, RequestUrl.url);
        int BodyBytesSent = GenerateBodyBytesSent(RequestMethod, RequestUrl.url, StatusCode);
        char* HttpRefferer = GenerateHttpReferer(RequestUrl.url);
        char* UserAgent = GenerateUserAgent();
        sprintf(LogString, "%s - - [%s %s] \"%s %s %s\" %d %d %s %s\n", RemoteAddr, Time, LocalUTC, RequestMethod, RequestUrl.url, HttpVersion,
            StatusCode, BodyBytesSent, HttpRefferer, UserAgent);
        fprintf(logfile, "%s", LogString);
        fflush(logfile);
    }
}

void GetRandomIp(char *RemoteAddr) {
    int Octet1, Octet2, Octet3, Octet4;
    do {
        Octet1=rand() % 256;
        Octet2=rand() % 256;
        Octet3=rand() % 256;
        Octet4=rand() % 256;
    } while (!IsAddrVarlid (Octet1, Octet2, Octet3, Octet4));

    sprintf(RemoteAddr, "%d.%d.%d.%d", Octet1, Octet2, Octet3, Octet4);


}

int IsAddrVarlid(int Octet1, int Octet2, int Octet3, int Octet4) {
    int status = 1;
    if (Octet1 == 0 && Octet2 == 0 && Octet3 == 0 && Octet4 == 0) status = 0;
    if (Octet1 == 255 && Octet2 == 255 && Octet3 == 255 && Octet4 == 255) status = 0; 
    if (Octet1 >= 224 && Octet1 <= 239) status = 0; // multicast
    if (Octet1 >= 240) status = 0; // reservertd ip
    return status;
}


bool IsLeapYear(int Year) {
    return (Year % 4 == 0 && Year % 100 != 0) || (Year % 400 == 0);
}
void TimeLocal(char *Time, int trigger) {
    static int loop=0;
    static time_t seconds;
    time_t SecInDay = 24 * 60 * 60;
    time_t SecInYear = SecInDay * 365;
    time_t time_to_back = SecInYear * 5; 
    time_t TimeShift = rand() % (60 * 60);

    if (trigger != 0) {
        seconds += (rand() % TimeShift);
    }
    else {
        seconds = time(NULL) - (rand() % time_to_back);
    }

    struct tm *utc_time = gmtime(&seconds);
    
    static const char* months[] = {
        "Jan", "Feb", "Mar", "Apr", "May", "Jun",
        "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
    };

    sprintf(Time, "%02d/%s/%04d:%02d:%02d:%02d",
        utc_time->tm_mday, months[utc_time->tm_mon], utc_time->tm_year + 1900,
        utc_time->tm_hour, utc_time->tm_min, utc_time->tm_sec);
    
    (trigger == 0)? loop = 0: loop++;
}

char* GetTimeZone(void) {
    char *TimeZoneArray[] = {
        "-1200", "-1100", "-1000", "-0900", "-0800", "-0700", "-0600",
        "-0500", "-0400", "-0300", "-0200", "-0100", "+0000",
        "+0100", "+0200", "+0300", "+0400", "+0500", "+0530", "+0545",
        "+0600", "+0630", "+0700", "+0800", "+0845", "+0900", "+0930",
        "+1000", "+1030", "+1100", "+1200", "+1245", "+1300", "+1400"
    };
    int number_time_zone = sizeof(TimeZoneArray)/sizeof(TimeZoneArray[0]);

    return (TimeZoneArray[(rand() %  number_time_zone)]);
}

void GetRequestMethod (char **RequestMethod) {
    char  *ActualMethods[] = {"GET", "POST", "PUT", "PATCH", "DELETE"};
    int NumMethods = sizeof(ActualMethods)/sizeof(ActualMethods[0]);
    *RequestMethod = ActualMethods[rand() % NumMethods];
}
char* GetHttpVersion() {
    
    return (rand() % 4 == 0) ? "HTTP/1.1" : "HTTP/2.0";  // 50% на каждый вариант
}

RequestUrl_t GetRequestUrl (char* RequestMethod) {
    if (strcmp(RequestMethod, "GET") == 0) {
        RequestUrl_t examples[] = {
            {"/index.html", "Main page request"},
            {"/products/123", "Product details"},
            {"/search?q=nginx", "Search request"},
            {"/user/profile", "User profile"},
            {"/nonexistent", "Non-existent resource"},
            {"/malformed%20url", "Invalid URL encoding"},
            {"/private/docs", "Restricted content"},
            {"/server-error", "Error page"}
        };
        return examples[rand() % 8];
    }
    else if (strcmp(RequestMethod, "POST") == 0) {
        RequestUrl_t examples[] = {
            {"/api/login", "User authentication"},
            {"/api/users", "User registration"},
            {"/api/orders", "Order creation"},
            {"/upload/image", "Image upload"},
            {"/submit-form", "Form submission"},
            {"/batch-process", "Batch processing"}
        };
        return examples[rand() % 6];
    }
    else if (strcmp(RequestMethod, "PUT") == 0) {
        RequestUrl_t examples[] = {
            {"/api/users/123", "User data update"},
            {"/api/products/456", "Product update"},
            {"/config/settings", "Configuration change"},
            {"/content/article", "Article update"}
        };
        return examples[rand() % 4];
    }
    else if (strcmp(RequestMethod, "PATCH") == 0) {
        RequestUrl_t examples[] = {
            {"/api/users/123/email", "Email update"},
            {"/api/orders/456/status", "Order status change"},
            {"/profile/settings", "Partial settings update"}
        };
        return examples[rand() % 3];
    }
    else if (strcmp(RequestMethod, "DELETE") == 0) {
        RequestUrl_t examples[] = {
            {"/api/users/123", "User deletion"},
            {"/api/products/456", "Product removal"},
            {"/storage/files/789", "File deletion"},
            {"/account", "Account termination"}
        };
        return examples[rand() % 4];
    }

    RequestUrl_t default_example = {"/", "Default request"};
    return default_example;
}
int GetStatusCodeForRequest(char* method, char* url) {
 
    if (strstr(url, "nonexistent") || strstr(url, "notfound")) 
        return 404;
    if (strstr(url, "malformed") || strstr(url, "invalid")) 
        return 400;
    if (strstr(url, "private") || strstr(url, "restricted") || strstr(url, "secret")) 
        return 403;
    if (strstr(url, "server-error") || strstr(url, "crash")) 
        return (rand() % 2) ? 500 : 503;
    if (strstr(url, "timeout") || strstr(url, "slow")) 
        return 504; 
    if (strstr(url, "redirect")) 
        return (rand() % 2) ? 301 : 302;

    if (strcmp(method, "GET") == 0) {
        if (strstr(url, "search") || strstr(url, "query")) 
            return (rand() % 2) ? 200 : 204;  
        if (strstr(url, "throttled")) 
            return 429; 
        return 200;
    }
    else if (strcmp(method, "POST") == 0) {
        if (strstr(url, "login")) 
            return (rand() % 3) == 0 ? 401 : 200;  
        if (strstr(url, "users")) 
            return (rand() % 2) ? 201 : 409; 
        if (strstr(url, "upload")) 
            return (rand() % 2) ? 200 : 413;
        if (strstr(url, "submit")) 
            return (rand() % 2) ? 200 : 422;
        return 200;
    }
    else if (strcmp(method, "PUT") == 0) {
        if (strstr(url, "config")) 
            return (rand() % 2) ? 200 : 403;
        if (strstr(url, "products") || strstr(url, "users")) 
            return (rand() % 2) ? 200 : 409; 
        return 200;
    }
    else if (strcmp(method, "PATCH") == 0) {
        if (strstr(url, "email") || strstr(url, "profile")) 
            return (rand() % 2) ? 200 : 400; 
        if (strstr(url, "status")) 
            return (rand() % 2) ? 200 : 428; 
        return 200;
    }
    else if (strcmp(method, "DELETE") == 0) {
        if (strstr(url, "account")) 
            return (rand() % 2) ? 200 : 403; 
        if (strstr(url, "files")) 
            return (rand() % 2) ? 200 : 404; 
        return (rand() % 2) ? 200 : 204; 
    }
    else if (strcmp(method, "HEAD") == 0) {
        return 200; 
    }
    else if (strcmp(method, "OPTIONS") == 0) {
        return 204; 
    }

 
    if (rand() % 2) 
        return 501;
    else 
        return 502;
}

int GenerateBodyBytesSent(char* method, char* url, int status_code) {

    if (status_code >= 400) {
        if (status_code == 404 || status_code == 403) 
            return (rand() % 100) + 50;  
        else if (status_code == 500) 
            return (rand() % 200) + 100; 
        return 0;  
    }

    if (strcmp(method, "HEAD") == 0) {
        return 0;  
    }

    if (strstr(url, ".html") || strstr(url, "/index")) {
        return (rand() % 5000) + 1000;  
    } 
    else if (strstr(url, ".json") || strstr(url, "/api")) {
        return (rand() % 3000) + 500;
    } 
    else if (strstr(url, ".jpg") || strstr(url, ".png")) {
        return (rand() % 500000) + 50000;
    } 
    else if (strstr(url, ".pdf") || strstr(url, "/document")) {
        return (rand() % 10000000) + 100000;
    }

    return (rand() % 10000) + 500; 
}

#include <stdlib.h>
#include <string.h>
#include <time.h>

char* GenerateHttpReferer(const char* url) {

    if (rand() % 4 == 0) {
        return "-";
    }

    if (rand() % 3 == 0) {
        char* internal_referers[] = {
            "https://DO4Linuxmonitoring20.com/",
            "https://DO4Linuxmonitoring20/home",
            "https://DO4Linuxmonitoring20/products",
            "https://DO4Linuxmonitoring20/login",
            "https://DO4Linuxmonitoring20/search?q=test"
        };
        return internal_referers[rand() % 5];
    }
        char* external_referers[] = {
        "https://www.google.com/search?q=nginx+tutorial",
        "https://yandex.ru/search/?text=how+to+configure+nginx",
        "https://www.bing.com/search?q=web+server",
        "https://facebook.com/l.php?u=DO4Linuxmonitoring20",
        "https://twitter.com/share?url=DO4Linuxmonitoring20",
        "https://reddit.com/r/programming",
        "https://medium.com/web-dev",
        "https://habr.com/ru/post/123456/",
        "https://vk.com/share.php?url=DO4Linuxmonitoring20",
        "https://linkedin.com/posts/example-nginx-123"
    };

    if (rand() % 10 == 0) {
        char* spam_referers[] = {
            "https://fake-traffic.com/xyz",
            "https://spambot.net/ref=123",
            "http://ads.scam/clickbait",
            "https://cheap-seo.com/promo"
        };
        return spam_referers[rand() % 4];
    }

    return external_referers[rand() % 10];
}

char* GenerateUserAgent(void) {

    typedef struct {
        char* agent;
        int weight; 
    } UserAgentWeight;

    static UserAgentWeight agents[] = {
        // ===== Современные браузеры (Mozilla-based) =====
        // Chrome (Windows/macOS/Linux)
        {"Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36", 15},
        {"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Safari/537.36", 10},
        {"Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/118.0.0.0 Safari/537.36", 8},

        // Firefox
        {"Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:120.0) Gecko/20100101 Firefox/120.0", 12},
        {"Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:109.0) Gecko/20100101 Firefox/119.0", 8},

        // Safari (macOS/iOS)
        {"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.6 Safari/605.1.15", 10},
        {"Mozilla/5.0 (iPhone; CPU iPhone OS 17_2 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.2 Mobile/15E148 Safari/604.1", 10},

        // Edge
        {"Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36 Edg/120.0.0.0", 10},

        // Opera
        {"Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36 OPR/106.0.0.0", 7},
        {"Opera/9.80 (Android; Opera Mini/82.0.2254/191.303; U; en) Presto/2.12.423 Version/12.16", 5},

        // ===== Устаревшие браузеры =====
        // Internet Explorer
        {"Mozilla/5.0 (Windows NT 10.0; WOW64; Trident/7.0; rv:11.0) like Gecko", 3},

        // ===== Боты и краулеры =====
        {"Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)", 8},
        {"Mozilla/5.0 (compatible; Bingbot/2.0; +http://www.bing.com/bingbot.htm)", 5},
        {"Mozilla/5.0 (compatible; YandexBot/3.0; +http://yandex.com/bots)", 5},
        {"facebookexternalhit/1.1 (+http://www.facebook.com/externalhit_uatext.php)", 3},

        // ===== Сетевые инструменты и библиотеки =====
        {"curl/7.81.0", 5},
        {"python-requests/2.28.1", 4},
        {"Java/17.0.9", 3},
        {"Wget/1.21.3", 3},
        {"Go-http-client/1.1", 3},
        {"Mozilla/5.0 (compatible; Nmap Scripting Engine; https://nmap.org/book/nse.html)", 2}
    };


    int total_weight = 0;
    for (size_t i = 0; i < sizeof(agents)/sizeof(agents[0]); i++) {
        total_weight += agents[i].weight;
    }

    int r = rand() % total_weight;
    int cumulative_weight = 0;
    for (size_t i = 0; i < sizeof(agents)/sizeof(agents[0]); i++) {
        cumulative_weight += agents[i].weight;
        if (r < cumulative_weight) {
            return agents[i].agent;
        }
    }

    return "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36";
}
