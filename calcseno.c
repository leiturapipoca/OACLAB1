float calcseno(float radianos, int termos) {
    const float EPS = 1e-7f;
    float x = normalize_angle(radianos);
    int sign = 1;
    if (x < 0.0f) { x = -x; sign = -1; }

    /* reduzir para [0, PI/2] usando sin(pi - t) = sin(t) */
    if (x > (PI * 0.5f)) {
        x = PI - x;
    }

    float x2 = x * x;
    float term = x;    /* k=0 */
    float sum  = term;

    for (int k = 1; k < termos; ++k) {
        float denom = (2.0f * k) * (2.0f * k + 1.0f);
        term *= - x2 / denom;
        sum += term;
        if (term < 0.0f ? -term < EPS : term < EPS) break;
    }
    return sign * sum;
}
