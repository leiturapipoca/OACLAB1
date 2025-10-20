
void DFT(float *x, float *X_real, float *X_imag, int N) {
    int qtd = 12; 
    for (int k = 0; k < N; k++) {
        float soma_real = 0.0f;
        float soma_imag = 0.0f;
        for (int n = 0; n < N; n++) {
            float ang = -2.0f * PI * (float)k * (float)n / (float)N;
            float c = calccosseno(ang, qtd);
            float s = calcseno(ang, qtd);
            soma_real += x[n] * c;
            soma_imag += x[n] * s;
        }
        X_real[k] = soma_real;
        X_imag[k] = soma_imag;
    }
}
