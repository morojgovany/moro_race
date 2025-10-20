const {createApp} = Vue;

createApp({
    data() {
        return {
            isVisible: false,
            timer: "00:00:00",
            serverOffset: 0,
            startTime: null,
            timeoutId: null,
            countdown: 3,
            isCountDownActive: false,
            interval: null,
        };
    },
    mounted() {
        window.addEventListener("message", this.onMessage);
    },
    methods: {
        onMessage(event) {
            const data = event.data;
            switch (data.action) {
                case "showTimer":
                    const serverTime = Number(data.serverTime);
                    this.serverOffset = Number.isFinite(serverTime) ? serverTime * 1000 - performance.now() : 0;
                    const startTime = Number(data.startTime);
                    this.startTime = Number.isFinite(startTime) ? startTime * 1000 : null;
                    if (this.isCountDownActive) {
                        this.isVisible = false;
                    } else {
                        this.startTimerDisplay();
                    }
                    break;
                case "hide":
                    this.isVisible = false;
                    this.startTime = null;
                    this.isCountDownActive = false;
                    this.countdown = 3;
                    if (this.interval) {
                        clearInterval(this.interval);
                        this.interval = null;
                    }
                    if (this.timeoutId) {
                        clearTimeout(this.timeoutId);
                        this.timeoutId = null;
                    }
                    break;
                case "showCountdown":
                    if (this.interval) {
                        clearInterval(this.interval);
                    }
                    this.countdown = 3;
                    this.isCountDownActive = true;
                    $("#start").css('textShadow', '#000000 10px 5px');
                    this.interval = setInterval(() => {
                        this.countdown--;
                        if (this.countdown === 0) {
                            $("#start").css('textShadow', '#991616 10px 5px');
                        }
                        if (this.countdown < 0) {
                            clearInterval(this.interval);
                            this.interval = null;
                            this.countdown = 3;
                            this.isCountDownActive = false;
                            $("#start").css('textShadow', '#000000 10px 5px');
                            this.startTimerDisplay();
                        }
                    }, 1000);
                    break;
                default:
                    this.isVisible = false;
                    break;
            }
        },
        startTimerDisplay() {
            if (this.startTime === null) {
                this.isVisible = false;
                return;
            }
            this.isVisible = true;
            this.update();
        },
        update() {
            if (!this.isVisible) return;
            const now = performance.now() + this.serverOffset;
            let diff;
            if (this.startTime === null) return;
            diff = Math.max(0, now - this.startTime);
            const totalSeconds = Math.floor(diff / 1000);
            const hours = Math.floor(totalSeconds / 3600);
            const minutes = Math.floor((totalSeconds % 3600) / 60);
            const seconds = totalSeconds % 60;
            const pad = v => String(v).padStart(2, "0");
            this.timer = `${pad(hours)}:${pad(minutes)}:${pad(seconds)}`;
            const remainder = diff % 1000;
            let delay;
            const normalized = 1000 - remainder;
            delay = normalized > 0 ? normalized : 1000;
            if (this.timeoutId) clearTimeout(this.timeoutId);
            this.timeoutId = setTimeout(() => this.update(), delay);
        }
    }
}).mount("#app");
