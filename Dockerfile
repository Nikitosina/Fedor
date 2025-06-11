# 1
FROM swift:5.10
WORKDIR /app
COPY . .

# 3
RUN swift package clean
RUN swift build -c release

# 4
RUN mkdir /app/bin
RUN mv `swift build --show-bin-path -c release` /app/bin

# 5
ENTRYPOINT ./bin/release/TradingBot

