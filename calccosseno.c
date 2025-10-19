float calccosseno(float radianos, int termos) {
    const float EPS = 1e-7f;
    float x = normalize_angle(radianos);

    //
    if (x < 0.0f) x = -x;

    /* reduzir para [0, PI/2] usando cos(pi - t) = -cos(t) pois a convergencia da serie e melhor perto do 0*/
    int sign = 1;
    if (x > (PI * 0.5f)) {
        x = PI - x;
        sign = -1;
    }

    float x2 = x * x;
    float term = 1.0f;      /* k=0 */
    float sum  = term;

    for (int k = 1; k < termos; ++k) {
        float denom = (2.0f * k - 1.0f) * (2.0f * k);
        term *= - x2 / denom;   /* termo recursivo */
        sum += term;
        if (term < 0.0f ? -term < EPS : term < EPS) break;
    }
    return sign * sum;
}
