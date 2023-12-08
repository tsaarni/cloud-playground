
/* Compile with:
 * gcc -Wall -o captest captest.c -lcap
 */

#include <linux/capability.h>
#include <stdio.h>
#include <sys/capability.h>
#include <string.h>
#include <errno.h>

typedef int (*cap_check_t)(cap_value_t);

int check_permitted(cap_value_t cap) {
    cap_flag_value_t enabled = -1;

    cap_t current = cap_get_proc();
    if (current == NULL) {
        printf("cap_get_proc: %s\n", strerror(errno));
        return 0;
    }

    if (cap_get_flag(current, cap, CAP_PERMITTED, &enabled) != 0) {
        printf("cap_get_flag: %s\n", strerror(errno));
        cap_free(current);
        return 0;
    }

    cap_free(current);

    return enabled;
}

void parse_caps(cap_check_t check) {
    char *text;
    for (int i = 0; i <= CAP_LAST_CAP; i++) {
        if (check(i)) {
            text = cap_to_name(i);
            printf("%s,", text);
            cap_free(text);
        }
    }
}

void print_all_caps() {
    cap_t caps;
    char *text;

    caps = cap_get_proc();
    text = cap_to_text(caps, NULL);
    printf("Effective: %s\n", text);
    cap_free(text);
    cap_free(caps);

    printf("Permitted: ");
    parse_caps(check_permitted);
    printf("\n");

    printf("Bounding: ");
    parse_caps(cap_get_bound);
    printf("\n");

    printf("Ambient: ");
    parse_caps(cap_get_ambient);
    printf("\n");
}

int main(int argc, char *argv[])
{
    cap_t caps;

    printf(">>>>>> Initial capabilities\n");

    print_all_caps();

    /* Dropping all capabilities */
    printf("\n>>>>>> Attempting to drop all capabilities\n");
    caps = cap_init();
    int res = cap_set_proc(caps);
    if (res != 0) {
        printf("cap_set_proc: %s\n", strerror(errno));
    }
    cap_free(caps);

    print_all_caps();

    /* Add CAP_NET_RAW to the effective set */
    printf("\n>>>>>> Attempting to add CAP_NET_RAW to the effective set\n");
    caps = cap_get_proc();
    cap_value_t cap_list[] = {CAP_NET_RAW};
    cap_set_flag(caps, CAP_EFFECTIVE, 1, cap_list, CAP_SET);
    res = cap_set_proc(caps);
    if (res != 0) {
        printf("cap_set_proc: %s\n", strerror(errno));
    }
    cap_free(caps);

    print_all_caps();

    return 0;
}
