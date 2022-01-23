package main

import (
	"context"
	"log"
	"net"
	"os"
	"time"

	"github.com/go-redis/redis/v8"
	"github.com/rschio/cloudrun/proto"
	"google.golang.org/grpc"
	"google.golang.org/grpc/reflection"
)

func mustEnv(key string) string {
	val := os.Getenv(key)
	if val == "" {
		log.Fatalf("empty key %q", key)
	}
	return val
}

func main() {
	redisAddr := mustEnv("REDIS_ADDR")
	redisPassword := mustEnv("REDIS_PASSWORD")
	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	opts := &redis.Options{
		Addr:     redisAddr,
		Password: redisPassword,
	}
	c := redis.NewClient(opts)
	defer c.Close()
	s := &Server{cache: c}

	l, err := net.Listen("tcp", ":"+port)
	if err != nil {
		log.Fatal(err)
	}

	srv := grpc.NewServer()
	proto.RegisterTimesServer(srv, s)
	reflection.Register(srv)
	if err := srv.Serve(l); err != nil {
		log.Println(err)
	}
}

func (s *Server) GetTimes(ctx context.Context, _ *proto.Output) (*proto.Output, error) {
	out := new(proto.Output)
	start := time.Now()
	err := s.cache.SetEX(ctx, "my-key", "my-val", time.Minute).Err()
	if err != nil {
		return nil, err
	}
	out.Set = time.Since(start).String()

	start = time.Now()
	_, err = s.cache.Get(ctx, "my-key").Result()
	if err != nil {
		return nil, err
	}
	out.Get = time.Since(start).String()
	return out, nil
}

type Server struct {
	cache *redis.Client
	proto.UnimplementedTimesServer
}
